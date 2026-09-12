"""Market data adapter. Yahoo is replaceable; views never call it directly."""
from __future__ import annotations

import json
import math
import random
import time
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
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
