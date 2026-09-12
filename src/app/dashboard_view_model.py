"""Qt view model: configured stocks and descriptive historical analysis."""
from __future__ import annotations

import tomllib
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict
from pathlib import Path

from PySide6.QtCore import QObject, Property, QThread, Signal, Slot

from core.analytics import analyze, correlation_matrix
from core.market_data import MarketDataError, fetch_history, simulated_history


class HistoryWorker(QThread):
    succeeded = Signal(object)
    failed = Signal(str)

    def __init__(self, ticker: str, years: int) -> None:
        super().__init__()
        self.ticker, self.years = ticker, years

    def run(self) -> None:
        try:
            self.succeeded.emit({"asset": fetch_history(self.ticker, self.years), "market": fetch_history("SPY", self.years)})
        except MarketDataError as error:
            self.failed.emit(str(error))


class CorrelationWorker(QThread):
    succeeded = Signal(object)
    failed = Signal(str)

    def __init__(self, tickers: list[str], years: int) -> None:
        super().__init__()
        self.tickers, self.years = tickers, years

    def run(self) -> None:
        try:
            with ThreadPoolExecutor(max_workers=len(self.tickers)) as pool:
                tasks = {ticker: pool.submit(fetch_history, ticker, self.years) for ticker in self.tickers}
                histories = {ticker: task.result().prices for ticker, task in tasks.items()}
            self.succeeded.emit(correlation_matrix(histories, self.tickers))
        except MarketDataError as error:
            self.failed.emit(str(error))


def _load_assets(project_root: Path) -> list[dict]:
    config_path = project_root / "config" / "config.toml"
    with config_path.open("rb") as config_file:
        configuration = tomllib.load(config_file)
    assets = configuration.get("assets", [])
    if not assets:
        raise ValueError("config/config.toml ne contient aucune action")
    return assets


class DashboardViewModel(QObject):
    changed = Signal()

    def __init__(self, project_root: Path) -> None:
        super().__init__()
        self._assets = _load_assets(project_root)
        self._ticker = self._assets[0]["ticker"]
        self._years = 5
        self._worker: HistoryWorker | None = None
        self._correlation_worker: CorrelationWorker | None = None
        self._state: dict = {}
        self._refresh_with_demo()
        self._fetch_live()
        self._fetch_correlation_live()

    @Property(str, notify=changed)
    def ticker(self) -> str:
        return self._ticker

    @Property(int, notify=changed)
    def years(self) -> int:
        return self._years

    @Property(str, notify=changed)
    def assetName(self) -> str:
        return self._asset()["name"]

    @Property(str, notify=changed)
    def market(self) -> str:
        return self._state.get("market", self._asset().get("market", ""))

    @Property(str, notify=changed)
    def assetLogo(self) -> str:
        return self._asset().get("logo", self._ticker[0])

    @Property(str, notify=changed)
    def accent(self) -> str:
        return self._asset().get("color", "#078a68")

    @Property(str, notify=changed)
    def accentSoft(self) -> str:
        return self._asset().get("soft_color", "#e6f4ee")

    @Property(str, notify=changed)
    def dataMode(self) -> str:
        return self._state.get("data_mode", "Chargement…")

    @Property("QVariantList", notify=changed)
    def assets(self) -> list[dict]:
        return self._assets

    @Property("QVariantMap", notify=changed)
    def headline(self) -> dict:
        return self._state.get("headline", {})

    @Property("QVariantList", notify=changed)
    def chartData(self) -> list[dict]:
        return self._state.get("chart_data", [])

    @Property("QVariantList", notify=changed)
    def months(self) -> list[dict]:
        return self._state.get("months", [])

    @Property("QVariantList", notify=changed)
    def weekdays(self) -> list[dict]:
        return self._state.get("weekdays", [])

    @Property("QVariantMap", notify=changed)
    def bestMonth(self) -> dict:
        return self._state.get("best_month", {})

    @Property("QVariantMap", notify=changed)
    def bestWeekday(self) -> dict:
        return self._state.get("best_weekday", {})

    @Property("QVariantList", notify=changed)
    def strategies(self) -> list[dict]:
        return self._state.get("strategies", [])

    @Property("QVariantList", notify=changed)
    def correlationMatrix(self) -> list[dict]:
        return self._state.get("correlation_matrix", [])

    @Property(str, notify=changed)
    def correlationDataMode(self) -> str:
        return self._state.get("correlation_data_mode", "Chargement de la matrice…")

    @Slot(str)
    def selectTicker(self, ticker: str) -> None:
        if ticker not in [asset["ticker"] for asset in self._assets]:
            return
        self._ticker = ticker
        self._refresh_with_demo()
        self._fetch_live()

    @Slot(int)
    def setYears(self, years: int) -> None:
        if years not in (3, 5, 10):
            return
        self._years = years
        self._refresh_with_demo(reset_matrix=True)
        self._fetch_live()
        self._fetch_correlation_live()

    def _asset(self) -> dict:
        return next(asset for asset in self._assets if asset["ticker"] == self._ticker)

    def _refresh_with_demo(self, reset_matrix: bool = False) -> None:
        demo_histories = {asset["ticker"]: simulated_history(asset["ticker"], self._years) for asset in self._assets}
        matrix = [] if reset_matrix else self._state.get("correlation_matrix", [])
        matrix_source = "Matrice démo · données simulées, non exploitables" if reset_matrix else self._state.get("correlation_data_mode", "")
        if not matrix:
            matrix = correlation_matrix(demo_histories, [asset["ticker"] for asset in self._assets])
            matrix_source = "Matrice démo · données simulées, non exploitables"
        self._apply(
            demo_histories[self._ticker],
            simulated_history("SPY", self._years),
            self._asset().get("market", ""),
            "Mode démo · données simulées, non exploitables",
            matrix,
            matrix_source,
        )

    def _fetch_live(self) -> None:
        worker = HistoryWorker(self._ticker, self._years)
        self._worker = worker
        ticker, years = self._ticker, self._years
        worker.succeeded.connect(lambda result: self._on_live(result, ticker, years))
        worker.failed.connect(lambda _: None)
        worker.start()

    def _on_live(self, result: dict, ticker: str, years: int) -> None:
        if ticker != self._ticker or years != self._years:
            return
        market = result["asset"].metadata.get("market") or self._asset().get("market", "")
        self._apply(result["asset"].prices, result["market"].prices, market, "Données Yahoo Finance · comparaison avec le S&P 500 (SPY)", self.correlationMatrix, self.correlationDataMode)

    def _fetch_correlation_live(self) -> None:
        tickers = [asset["ticker"] for asset in self._assets]
        worker = CorrelationWorker(tickers, self._years)
        self._correlation_worker = worker
        years = self._years
        worker.succeeded.connect(lambda matrix: self._on_correlation_live(matrix, years))
        worker.failed.connect(lambda _: None)
        worker.start()

    def _on_correlation_live(self, matrix: list[dict], years: int) -> None:
        if years != self._years:
            return
        self._state["correlation_matrix"] = matrix
        self._state["correlation_data_mode"] = "Matrice Yahoo Finance · rendements journaliers ajustés"
        self.changed.emit()

    def _apply(self, asset, benchmark, market: str, source: str, matrix: list[dict], matrix_source: str) -> None:
        report = analyze(asset, benchmark, self._years)
        self._state = {**asdict(report), "market": market, "data_mode": source, "correlation_matrix": matrix, "correlation_data_mode": matrix_source}
        self.changed.emit()
