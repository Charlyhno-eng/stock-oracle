"""Descriptive historical statistics shown by the dashboard."""
from __future__ import annotations

import math
from dataclasses import dataclass
from statistics import mean, median

from core.market_data import Price


def _mean(values: list[float]) -> float:
    return mean(values) if values else 0.0


def _percent(value: float, language: str, digits: int = 1) -> str:
    formatted = f"{value * 100:+.{digits}f} %"
    return formatted.replace(".", ",") if language == "fr" else formatted


def _ratio(value: float | None, language: str) -> str:
    if value is None:
        return "N/D" if language == "fr" else "N/A"
    formatted = f"{value:.1f}×"
    return formatted.replace(".", ",") if language == "fr" else formatted


def _correlation(left: list[float], right: list[float]) -> float:
    if len(left) < 2 or len(left) != len(right):
        return 0.0
    left_mean, right_mean = _mean(left), _mean(right)
    numerator = sum((x - left_mean) * (y - right_mean) for x, y in zip(left, right))
    left_scale = math.sqrt(sum((x - left_mean) ** 2 for x in left))
    right_scale = math.sqrt(sum((y - right_mean) ** 2 for y in right))
    return numerator / (left_scale * right_scale) if left_scale and right_scale else 0.0


def correlation_matrix(histories: dict[str, list[Price]], tickers: list[str]) -> list[dict]:
    """Pearson correlation of aligned daily adjusted-close returns."""
    returns_by_ticker: dict[str, dict] = {}
    for ticker in tickers:
        prices = histories[ticker]
        returns_by_ticker[ticker] = {
            current.timestamp.date(): current.adjusted_close / previous.adjusted_close - 1
            for previous, current in zip(prices, prices[1:])
        }
    rows = []
    for ticker in tickers:
        cells = []
        for other_ticker in tickers:
            shared_dates = sorted(set(returns_by_ticker[ticker]) & set(returns_by_ticker[other_ticker]))
            value = _correlation(
                [returns_by_ticker[ticker][date] for date in shared_dates],
                [returns_by_ticker[other_ticker][date] for date in shared_dates],
            )
            magnitude = min(1, abs(value))
            red = int(235 - magnitude * 100)
            green = int(245 - magnitude * 65)
            blue = int(240 - magnitude * 55)
            cells.append({"ticker": other_ticker, "value": value, "color": f"#{red:02x}{green:02x}{blue:02x}"})
        rows.append({"ticker": ticker, "cells": cells})
    return rows


def _strategy(values: list[float], label: str, description: str, language: str) -> dict:
    total = 1.0
    for value in values:
        total *= 1 + value
    return {
        "label": label,
        "description": description,
        "value": _percent(total - 1, language),
        "average": _percent(_mean(values), language, 2),
        "sessions": len(values),
        "positive": f"{_mean([float(value > 0) for value in values]) * 100:.0f} %" if values else "—",
    }


@dataclass
class HistoricalReport:
    headline: dict
    chart_data: list[dict]
    months: list[dict]
    weekdays: list[dict]
    best_month: dict
    best_weekday: dict
    strategies: list[dict]
    valuation: dict


def analyze(prices: list[Price], benchmark: list[Price], years: int, valuation=None, language: str = "fr") -> HistoricalReport:
    """Build descriptive results only; no forecast or trading recommendation."""
    benchmark_by_date = {point.timestamp.date(): point.adjusted_close for point in benchmark}
    aligned = [(point, benchmark_by_date[point.timestamp.date()]) for point in prices if point.timestamp.date() in benchmark_by_date]
    if len(aligned) < 2:
        raise ValueError("Historique S&P 500 insuffisant pour la comparaison")

    base_asset, base_market = aligned[0][0].adjusted_close, aligned[0][1]
    chart_data = [
        {"asset": point.adjusted_close / base_asset * 100, "sp500": market_close / base_market * 100}
        for point, market_close in aligned
    ]
    asset_return = chart_data[-1]["asset"] / 100 - 1
    market_return = chart_data[-1]["sp500"] / 100 - 1

    monthly_values = [[] for _ in range(12)]
    weekday_values = [[] for _ in range(5)]
    for previous, current in zip(prices, prices[1:]):
        daily_return = current.adjusted_close / previous.adjusted_close - 1
        monthly_values[current.timestamp.month - 1].append(daily_return)
        weekday_values[current.timestamp.weekday()].append(daily_return)

    month_labels = (
        ["Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Août", "Sep", "Oct", "Nov", "Déc"]
        if language == "fr" else ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    )
    weekday_labels = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi"] if language == "fr" else ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    months = [{"label": label, "value": _mean(values) * 100, "observations": len(values)} for label, values in zip(month_labels, monthly_values)]
    weekdays = [{"label": label, "value": _mean(values) * 100, "observations": len(values)} for label, values in zip(weekday_labels, weekday_values)]
    best_month = max(months, key=lambda item: item["value"])
    best_weekday = max(weekdays, key=lambda item: item["value"])

    intraday = [point.close / point.open - 1 for point in prices if point.open and point.close]
    overnight = [current.open / previous.close - 1 for previous, current in zip(prices, prices[1:]) if previous.close and current.open]
    strategies = [
        _strategy(intraday, "Ouverture → clôture" if language == "fr" else "Open → close", "Achat à l’ouverture, vente à la clôture de chaque séance." if language == "fr" else "Buy at the open and sell at the close of each session.", language),
        _strategy(overnight, "Clôture → ouverture" if language == "fr" else "Close → open", "Achat à la clôture, vente à l’ouverture de la séance suivante." if language == "fr" else "Buy at the close and sell at the next session’s open.", language),
    ]
    pe_values = [value for value in getattr(valuation, "historical_pe", []) if value > 0]
    current_pe = getattr(valuation, "current_pe", None)

    return HistoricalReport(
        headline={
            "asset_return": _percent(asset_return, language),
            "sp500_return": _percent(market_return, language),
            "difference": _percent(asset_return - market_return, language),
            "sessions": len(aligned),
            "start": aligned[0][0].timestamp.strftime("%d/%m/%Y" if language == "fr" else "%Y-%m-%d"),
            "end": aligned[-1][0].timestamp.strftime("%d/%m/%Y" if language == "fr" else "%Y-%m-%d"),
        },
        chart_data=chart_data,
        months=months,
        weekdays=weekdays,
        best_month={"label": best_month["label"], "value": _percent(best_month["value"] / 100, language, 2), "observations": best_month["observations"]},
        best_weekday={"label": best_weekday["label"], "value": _percent(best_weekday["value"] / 100, language, 2), "observations": best_weekday["observations"]},
        strategies=strategies,
        valuation={"current": _ratio(current_pe, language), "median": _ratio(median(pe_values) if pe_values else None, language), "mean": _ratio(_mean(pe_values) if pe_values else None, language), "observations": len(pe_values)},
    )
