"""Qt view model: configured stocks and descriptive historical analysis."""
from __future__ import annotations

import tomllib
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict
from pathlib import Path

from PySide6.QtCore import QObject, Property, QThread, Signal, Slot

from core.analytics import analyze, correlation_matrix
from core.market_data import MarketDataError, Valuation, fetch_history, fetch_valuation, simulated_history


TEXT = {
    "fr": {
        "historical_analysis": "Analyse historique", "available_assets": "ACTIONS DISPONIBLES",
        "study_period": "PÉRIODE D’ÉTUDE", "years": "ans", "view_matrix": "Voir la matrice de corrélation  ↓",
        "historical_only": "Constats historiques uniquement — pas une recommandation d’investissement.",
        "header_analysis": "ANALYSE HISTORIQUE", "period_observed": "PÉRIODE OBSERVÉE",
        "common_sessions": "séances communes", "asset_performance": "PERFORMANCE DE L’ACTION",
        "base_100_start": "Base 100 au début de la période", "same_period": "performance sur la même période",
        "gap_asset_market": "ÉCART ACTION / S&P 500", "outperformance": "surperformance ou sous-performance",
        "comparison": "COMPARAISON", "cumulative_performance": "Performance cumulée : action vs S&P 500",
        "base_100": "Base 100", "seasonality": "SAISONNALITÉ", "monthly_average": "Rendement moyen par mois",
        "best_month": "Meilleur mois observé : ", "sessions": "séances",
        "monthly_note": "Moyenne des rendements quotidiens du mois, calculée sur l’historique disponible.",
        "weekly_rhythm": "RYTHME HEBDOMADAIRE", "daily_average": "Rendement moyen par jour",
        "best_day": "Meilleur jour observé : ", "history_not_predictive": "Un historique ne prédit pas le prochain jour.",
        "historical_exercises": "EXERCICES HISTORIQUES", "two_ways": "Deux façons de détenir l’action",
        "cumulative": "PERFORMANCE CUMULÉE", "average_session": "MOYENNE / SÉANCE", "positive": "positives",
        "costs_excluded": "hors frais, fiscalité et slippage",
        "reading": "Lecture : les mois et jours affichés sont des constats descriptifs. Les performances des stratégies supposent une exécution exacte aux cours d’ouverture et de clôture, sans frais, taxes ni impact de marché.",
        "correlations": "CORRÉLATIONS", "matrix_title": "Matrice des actions disponibles",
        "pearson": "Corrélation de Pearson entre les rendements journaliers des titres.",
        "correlation_note": "1 = mouvements très proches ; 0 = absence de relation linéaire ; −1 = évolutions opposées. Une corrélation ne prédit pas les rendements futurs.",
        "valuation": "VALORISATION", "pe_title": "Ratio cours / bénéfice (PER)", "current_pe": "PER ACTUEL",
        "median_pe": "PER MÉDIAN", "mean_pe": "PER MOYEN", "period": "sur la période sélectionnée",
        "pe_observations": "observations de PER disponibles", "loading": "Chargement…",
        "demo_data": "Mode démo · données simulées, non exploitables", "demo_matrix": "Matrice démo · données simulées, non exploitables",
        "yahoo_data": "Données Yahoo Finance · comparaison avec le S&P 500 (SPY)",
        "yahoo_matrix": "Matrice Yahoo Finance · rendements journaliers ajustés", "loading_matrix": "Chargement de la matrice…",
    },
    "en": {
        "historical_analysis": "Historical analysis", "available_assets": "AVAILABLE STOCKS",
        "study_period": "STUDY PERIOD", "years": "years", "view_matrix": "View correlation matrix  ↓",
        "historical_only": "Historical observations only — not investment advice.",
        "header_analysis": "HISTORICAL ANALYSIS", "period_observed": "OBSERVED PERIOD",
        "common_sessions": "shared sessions", "asset_performance": "STOCK PERFORMANCE",
        "base_100_start": "Base 100 at the start of the period", "same_period": "performance over the same period",
        "gap_asset_market": "STOCK / S&P 500 GAP", "outperformance": "outperformance or underperformance",
        "comparison": "COMPARISON", "cumulative_performance": "Cumulative performance: stock vs S&P 500",
        "base_100": "Base 100", "seasonality": "SEASONALITY", "monthly_average": "Average return by month",
        "best_month": "Best observed month: ", "sessions": "sessions",
        "monthly_note": "Average daily return for each month, calculated from available history.",
        "weekly_rhythm": "WEEKLY RHYTHM", "daily_average": "Average return by weekday",
        "best_day": "Best observed day: ", "history_not_predictive": "Historical data do not predict the next day.",
        "historical_exercises": "HISTORICAL EXERCISES", "two_ways": "Two ways of holding the stock",
        "cumulative": "CUMULATIVE PERFORMANCE", "average_session": "AVERAGE / SESSION", "positive": "positive",
        "costs_excluded": "excluding costs, taxes and slippage",
        "reading": "Note: the displayed months and weekdays are descriptive observations. Strategy performances assume exact execution at opening and closing prices, with no fees, taxes or market impact.",
        "correlations": "CORRELATIONS", "matrix_title": "Available-stocks matrix",
        "pearson": "Pearson correlation between the stocks’ daily returns.",
        "correlation_note": "1 = very similar movements; 0 = no linear relationship; −1 = opposite movements. Correlation does not predict future returns.",
        "valuation": "VALUATION", "pe_title": "Price-to-earnings ratio (P/E)", "current_pe": "CURRENT P/E",
        "median_pe": "MEDIAN P/E", "mean_pe": "AVERAGE P/E", "period": "over the selected period",
        "pe_observations": "P/E observations available", "loading": "Loading…",
        "demo_data": "Demo mode · simulated data, not suitable for analysis", "demo_matrix": "Demo matrix · simulated data, not suitable for analysis",
        "yahoo_data": "Yahoo Finance data · comparison with the S&P 500 (SPY)",
        "yahoo_matrix": "Yahoo Finance matrix · adjusted daily returns", "loading_matrix": "Loading matrix…",
    },
}


class HistoryWorker(QThread):
    succeeded = Signal(object)
    failed = Signal(str)

    def __init__(self, ticker: str, benchmark: str, years: int, timeout: int) -> None:
        super().__init__()
        self.ticker, self.benchmark, self.years, self.timeout = ticker, benchmark, years, timeout

    def run(self) -> None:
        try:
            with ThreadPoolExecutor(max_workers=3) as pool:
                asset_task = pool.submit(fetch_history, self.ticker, self.years, self.timeout)
                market_task = pool.submit(fetch_history, self.benchmark, self.years, self.timeout)
                valuation_task = pool.submit(fetch_valuation, self.ticker, self.years, self.timeout)
                asset, market = asset_task.result(), market_task.result()
                try:
                    valuation = valuation_task.result()
                except MarketDataError:
                    # A missing P/E must not hide otherwise valid price analysis.
                    valuation = Valuation(None, [])
            self.succeeded.emit({
                "asset": asset,
                "market": market,
                "valuation": valuation,
            })
        except MarketDataError as error:
            self.failed.emit(str(error))


class CorrelationWorker(QThread):
    succeeded = Signal(object)
    failed = Signal(str)

    def __init__(self, tickers: list[str], years: int, timeout: int) -> None:
        super().__init__()
        self.tickers, self.years, self.timeout = tickers, years, timeout

    def run(self) -> None:
        try:
            with ThreadPoolExecutor(max_workers=len(self.tickers)) as pool:
                tasks = {ticker: pool.submit(fetch_history, ticker, self.years, self.timeout) for ticker in self.tickers}
                histories = {ticker: task.result().prices for ticker, task in tasks.items()}
            self.succeeded.emit(correlation_matrix(histories, self.tickers))
        except MarketDataError as error:
            self.failed.emit(str(error))


def _load_configuration(project_root: Path) -> dict:
    config_path = project_root / "config" / "config.toml"
    with config_path.open("rb") as config_file:
        configuration = tomllib.load(config_file)
    if not configuration.get("assets", []):
        raise ValueError("config/config.toml ne contient aucune action")
    return configuration


class DashboardViewModel(QObject):
    changed = Signal()

    def __init__(self, project_root: Path) -> None:
        super().__init__()
        configuration = _load_configuration(project_root)
        self._assets = configuration["assets"]
        application = configuration.get("application", {})
        market_data = configuration.get("market_data", {})
        configured_language = application.get("language", "fr").lower()
        self._language = configured_language if configured_language in TEXT else "fr"
        self._benchmark = market_data.get("benchmark", "SPY")
        self._timeout = int(market_data.get("timeout_seconds", 12))
        self._ticker = self._assets[0]["ticker"]
        configured_years = int(application.get("default_years", 5))
        self._years = configured_years if configured_years in (3, 5, 10) else 5
        self._worker: HistoryWorker | None = None
        self._correlation_worker: CorrelationWorker | None = None
        self._state: dict = {}
        self._live_ticker: str | None = None
        self._live_years: int | None = None
        self._live_result: dict | None = None
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
        key = "market_en" if self._language == "en" else "market"
        return self._state.get("market", self._asset().get(key, self._asset().get("market", "")))

    @Property(str, notify=changed)
    def language(self) -> str:
        return self._language

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
        return self._state.get("data_mode", self.i18n("loading"))

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

    @Property("QVariantMap", notify=changed)
    def valuation(self) -> dict:
        unavailable = "N/D" if self._language == "fr" else "N/A"
        return self._state.get("valuation", {"current": unavailable, "median": unavailable, "mean": unavailable, "observations": 0})

    @Property("QVariantList", notify=changed)
    def correlationMatrix(self) -> list[dict]:
        return self._state.get("correlation_matrix", [])

    @Property(str, notify=changed)
    def correlationDataMode(self) -> str:
        return self._state.get("correlation_data_mode", self.i18n("loading_matrix"))

    @Slot(str, str, result=str)
    def i18n(self, key: str, language: str | None = None) -> str:
        """Return a translation for QML, tracking its explicit language argument."""
        selected_language = language if language in TEXT else self._language
        return TEXT[selected_language].get(key, key)

    @Slot(str)
    def selectTicker(self, ticker: str) -> None:
        if ticker not in [asset["ticker"] for asset in self._assets]:
            return
        self._ticker = ticker
        self._live_ticker = None
        self._live_result = None
        self._refresh_with_demo()
        self._fetch_live()

    @Slot(int)
    def setYears(self, years: int) -> None:
        if years not in (3, 5, 10):
            return
        self._years = years
        self._live_ticker = None
        self._live_result = None
        self._refresh_with_demo(reset_matrix=True)
        self._fetch_live()
        self._fetch_correlation_live()

    @Slot(str)
    def setLanguage(self, language: str) -> None:
        if language not in TEXT or language == self._language:
            return
        self._language = language
        if self._live_result and self._live_ticker == self._ticker and self._live_years == self._years:
            result = self._live_result
            market = result["asset"].metadata.get("market") or self._asset().get("market_en" if language == "en" else "market", "")
            matrix_source = self.i18n("yahoo_matrix") if "Yahoo" in self.correlationDataMode else self.i18n("demo_matrix")
            self._apply(result["asset"].prices, result["market"].prices, market, self.i18n("yahoo_data"), self.correlationMatrix, matrix_source, result["valuation"])
        else:
            self._refresh_with_demo()

    def _asset(self) -> dict:
        return next(asset for asset in self._assets if asset["ticker"] == self._ticker)

    def _refresh_with_demo(self, reset_matrix: bool = False) -> None:
        demo_histories = {asset["ticker"]: simulated_history(asset["ticker"], self._years) for asset in self._assets}
        matrix = [] if reset_matrix else self._state.get("correlation_matrix", [])
        existing_matrix_source = self._state.get("correlation_data_mode", "")
        matrix_source = self.i18n("demo_matrix") if reset_matrix else (
            self.i18n("yahoo_matrix") if "Yahoo" in existing_matrix_source else self.i18n("demo_matrix")
        )
        if not matrix:
            matrix = correlation_matrix(demo_histories, [asset["ticker"] for asset in self._assets])
            matrix_source = self.i18n("demo_matrix")
        self._apply(
            demo_histories[self._ticker],
            simulated_history("SPY", self._years),
            self._asset().get("market_en" if self._language == "en" else "market", ""),
            self.i18n("demo_data"),
            matrix,
            matrix_source,
            Valuation(None, []),
        )

    def _fetch_live(self) -> None:
        worker = HistoryWorker(self._ticker, self._benchmark, self._years, self._timeout)
        self._worker = worker
        ticker, years = self._ticker, self._years
        worker.succeeded.connect(lambda result: self._on_live(result, ticker, years))
        worker.failed.connect(lambda _: None)
        worker.start()

    def _on_live(self, result: dict, ticker: str, years: int) -> None:
        if ticker != self._ticker or years != self._years:
            return
        market = result["asset"].metadata.get("market") or self._asset().get("market_en" if self._language == "en" else "market", "")
        self._live_ticker, self._live_years, self._live_result = ticker, years, result
        self._apply(result["asset"].prices, result["market"].prices, market, self.i18n("yahoo_data"), self.correlationMatrix, self.correlationDataMode, result["valuation"])

    def _fetch_correlation_live(self) -> None:
        tickers = [asset["ticker"] for asset in self._assets]
        worker = CorrelationWorker(tickers, self._years, self._timeout)
        self._correlation_worker = worker
        years = self._years
        worker.succeeded.connect(lambda matrix: self._on_correlation_live(matrix, years))
        worker.failed.connect(lambda _: None)
        worker.start()

    def _on_correlation_live(self, matrix: list[dict], years: int) -> None:
        if years != self._years:
            return
        self._state["correlation_matrix"] = matrix
        self._state["correlation_data_mode"] = self.i18n("yahoo_matrix")
        self.changed.emit()

    def _apply(self, asset, benchmark, market: str, source: str, matrix: list[dict], matrix_source: str, valuation: Valuation) -> None:
        report = analyze(asset, benchmark, self._years, valuation, self._language)
        self._state = {**asdict(report), "market": market, "data_mode": source, "correlation_matrix": matrix, "correlation_data_mode": matrix_source}
        self.changed.emit()
