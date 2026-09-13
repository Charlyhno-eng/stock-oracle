"""Market data adapter. Yahoo is replaceable; views never call it directly."""
from __future__ import annotations

import json
import math
import random
import time
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from urllib.parse import quote
from urllib.error import URLError
from urllib.request import Request, urlopen


class MarketDataError(RuntimeError):
    pass


@dataclass(frozen=True)
class Price:
    timestamp: datetime
    open: float
    close: float
    adjusted_close: float


@dataclass(frozen=True)
class History:
    prices: list[Price]
    metadata: dict[str, str]


@dataclass(frozen=True)
class Valuation:
    """Trailing P/E observations supplied by Yahoo Finance."""

    current_pe: float | None
    historical_pe: list[float]


def fetch_history(ticker: str, years: int, timeout: int = 12) -> History:
    end = int(time.time())
    start = end - years * 366 * 86400
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{ticker}?period1={start}&period2={end}&interval=1d&events=history&includeAdjustedClose=true"
    request = Request(url, headers={"User-Agent": "Stock-Oracle/1.0 local desktop application"})
    try:
        with urlopen(request, timeout=timeout) as response:
            payload = json.load(response)
    except (URLError, TimeoutError, json.JSONDecodeError) as error:
        raise MarketDataError("Source de marché indisponible") from error
    result = payload.get("chart", {}).get("result", [None])[0]
    if not result:
        raise MarketDataError("Ticker inconnu ou historique indisponible")
    timestamps = result.get("timestamp", [])
    quote = result.get("indicators", {}).get("quote", [{}])[0]
    opens, closes = quote.get("open", []), quote.get("close", [])
    adjusted = result.get("indicators", {}).get("adjclose", [{}])[0].get("adjclose") or closes
    prices = []
    for timestamp, opening, closing, adjusted_close in zip(timestamps, opens, closes, adjusted):
        if all(value is not None and math.isfinite(value) and value > 0 for value in (opening, closing, adjusted_close)):
            prices.append(Price(datetime.fromtimestamp(timestamp, tz=timezone.utc), float(opening), float(closing), float(adjusted_close)))
    if len(prices) < 40:
        raise MarketDataError("Historique insuffisant")
    meta = result.get("meta", {})
    return History(prices, {"name": meta.get("longName") or meta.get("shortName") or ticker, "market": " · ".join(filter(None, [meta.get("fullExchangeName") or meta.get("exchangeName"), meta.get("currency")]))})


def _finite_positive(value: object) -> float | None:
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return number if math.isfinite(number) and number > 0 else None


def _load_json(url: str, timeout: int) -> dict:
    request = Request(url, headers={"User-Agent": "Stock-Oracle/1.0 local desktop application"})
    try:
        with urlopen(request, timeout=timeout) as response:
            return json.load(response)
    except (URLError, TimeoutError, json.JSONDecodeError) as error:
        raise MarketDataError("Market data source unavailable") from error


def fetch_valuation(ticker: str, years: int, timeout: int = 12) -> Valuation:
    """Fetch the current and in-period trailing P/E series when Yahoo provides it.

    P/E is not present in price history, so unavailable or non-meaningful (negative)
    values are deliberately omitted rather than estimated from prices.
    """
    end = int(time.time())
    start = end - years * 366 * 86400
    encoded_ticker = quote(ticker, safe="")
    series_url = (
        "https://query1.finance.yahoo.com/ws/fundamentals-timeseries/v1/finance/"
        f"timeseries/{encoded_ticker}?symbol={encoded_ticker}&type=trailingPeRatio"
        f"&period1={start}&period2={end}"
    )
    payload = _load_json(series_url, timeout)
    values: list[tuple[str, float]] = []
    for result in payload.get("timeseries", {}).get("result", []):
        for entry in result.get("trailingPeRatio", []):
            value = _finite_positive(entry.get("reportedValue", {}).get("raw"))
            if value is not None:
                values.append((entry.get("asOfDate", ""), value))
    values.sort(key=lambda item: item[0])
    historical = [value for _, value in values]
    current = historical[-1] if historical else None

    # The quote endpoint is more current than a fundamentals observation when it
    # is available.  It is optional because Yahoo may restrict it intermittently.
    try:
        quote_payload = _load_json(
            f"https://query1.finance.yahoo.com/v7/finance/quote?symbols={encoded_ticker}", timeout
        )
        quote_result = quote_payload.get("quoteResponse", {}).get("result", [])
        quote_pe = _finite_positive(quote_result[0].get("trailingPE")) if quote_result else None
        current = quote_pe or current
    except MarketDataError:
        pass
    return Valuation(current, historical)


def simulated_history(ticker: str, years: int) -> list[Price]:
    """Explicit offline fallback, never presented as a market-data result."""
    seed = sum((index + 1) * ord(char) for index, char in enumerate(ticker))
    randomizer = random.Random(seed + years)
    close = 75 + seed % 210
    start = datetime.now(tz=timezone.utc) - timedelta(days=years * 365)
    data: list[Price] = []
    for day in range(years * 366):
        timestamp = start + timedelta(days=day)
        if timestamp.weekday() < 5:
            opening = close * (1 + randomizer.gauss(0, 0.006))
            close = opening * (1 + 0.0003 + randomizer.gauss(0, 0.014))
            data.append(Price(timestamp, max(opening, 1), max(close, 1), max(close, 1)))
    return data
