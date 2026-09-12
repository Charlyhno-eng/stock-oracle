"""Desktop entry point for Stock Oracle."""
from __future__ import annotations

import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from app.dashboard_view_model import DashboardViewModel


ROOT = Path(__file__).resolve().parent


def main() -> int:
    application = QGuiApplication(sys.argv)
    application.setApplicationName("Stock Oracle")
    application.setOrganizationName("Stock Oracle")

    engine = QQmlApplicationEngine()
    view_model = DashboardViewModel(ROOT.parent)
    engine.rootContext().setContextProperty("dashboard", view_model)
    engine.rootContext().setContextProperty(
        "brandLogoPath",
        QUrl.fromLocalFile(str(ROOT.parent / "assets" / "stock-oracle-logo.png")).toString(),
    )
    engine.load(QUrl.fromLocalFile(str(ROOT / "ui" / "Main.qml")))
    if not engine.rootObjects():
        return 1
    return application.exec()


if __name__ == "__main__":
    raise SystemExit(main())
