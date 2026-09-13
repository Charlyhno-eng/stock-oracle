import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

ApplicationWindow {
    id: root
    width: 1440
    height: 940
    minimumWidth: 1060
    minimumHeight: 720
    visible: true
    title: "Stock Oracle"
    color: "#fbfcfb"

    // Passing the language as an argument makes every text binding react to the
    // FR/EN switch; calls to a QObject method alone are not observable by QML.
    function t(key) {
        return dashboard.i18n(key, dashboard.language)
    }

    Rectangle {
        id: sidebar
        width: 270
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: "white"
        border.color: "#e5e9e8"

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 9

            Row {
                height: 54
                spacing: 8
                Image {
                    width: 38
                    height: 38
                    source: brandLogoPath
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text { text: "Stock Oracle"; color: "#19252e"; font.family: "Georgia"; font.bold: true; font.pixelSize: 21; anchors.verticalCenter: parent.verticalCenter }
            }
            Rectangle { width: parent.width; height: 42; radius: 7; color: "#edf5f1"
                Text { anchors.left: parent.left; anchors.leftMargin: 13; anchors.verticalCenter: parent.verticalCenter; text: "▣   " + root.t("historical_analysis"); color: "#176f5a"; font.bold: true; font.pixelSize: 13 }
            }
            Item { width: 1; height: 13 }
            Text { text: root.t("available_assets"); color: "#8a9298"; font.pixelSize: 10; font.letterSpacing: 1 }
            Repeater {
                model: dashboard.assets
                delegate: Button {
                    required property var modelData
                    width: parent.width; height: 45
                    background: Rectangle { radius: 6; color: dashboard.ticker === modelData.ticker ? dashboard.accentSoft : "transparent" }
                    contentItem: Row {
                        spacing: 9
                        Rectangle { width: 26; height: 26; radius: 6; color: modelData.soft_color; anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: modelData.logo; color: modelData.color; font.bold: true; font.pixelSize: 11 }
                        }
                        Column { anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Text { text: modelData.name; color: "#30404a"; font.bold: true; font.pixelSize: 12 }
                            Text { text: modelData.ticker; color: "#8b949a"; font.pixelSize: 10 }
                        }
                    }
                    onClicked: dashboard.selectTicker(modelData.ticker)
                }
            }
            Item { width: 1; height: 7 }
            Text { text: root.t("study_period"); color: "#8a9298"; font.pixelSize: 10; font.letterSpacing: 1 }
            Row {
                spacing: 6
                Repeater {
                    model: [3, 5, 10]
                    delegate: Button {
                        required property var modelData
                        width: 68; height: 33; text: modelData + " " + root.t("years")
                        background: Rectangle { radius: 4; border.color: "#dce2e1"; color: dashboard.years === modelData ? "#1f6053" : "white" }
                        contentItem: Text { text: parent.text; color: dashboard.years === modelData ? "white" : "#6f7d83"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 11 }
                        onClicked: dashboard.setYears(modelData)
                    }
                }
            }
            Button {
                width: parent.width; height: 35
                text: root.t("view_matrix")
                background: Rectangle { radius: 5; color: "#f3f6f5"; border.color: "#dce6e2" }
                contentItem: Text { text: parent.text; color: "#397766"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; font.pixelSize: 10 }
                onClicked: contentView.contentY = Math.max(0, Math.min(contentView.contentHeight - contentView.height, correlationSection.y - 20))
            }
            Item { height: Math.max(0, parent.height - 650) }
            Rectangle { width: parent.width; height: 1; color: "#e5e9e8" }
            Row { width: parent.width; spacing: 5
                Rectangle { width: 6; height: 6; radius: 3; color: dashboard.dataMode.indexOf("Yahoo") >= 0 ? "#20a37a" : "#eaa42c"; anchors.verticalCenter: parent.verticalCenter }
                Text { width: sidebar.width - 54; text: dashboard.dataMode; color: "#858e94"; font.pixelSize: 9; wrapMode: Text.WordWrap }
            }
            Text { width: parent.width; text: root.t("historical_only"); color: "#a0a7aa"; font.pixelSize: 9; wrapMode: Text.WordWrap }
        }
    }

    Rectangle {
        anchors.left: sidebar.right; anchors.right: parent.right; anchors.top: parent.top
        height: 67; color: "white"; border.color: "#e5e9e8"
        Text { anchors.left: parent.left; anchors.leftMargin: 55; anchors.verticalCenter: parent.verticalCenter; text: root.t("header_analysis") + "   /   " + dashboard.ticker; color: "#668179"; font.bold: true; font.pixelSize: 11 }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 30; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            Repeater {
                model: ["fr", "en"]
                delegate: Button {
                    required property var modelData
                    width: 34; height: 27; text: modelData.toUpperCase()
                    background: Rectangle { radius: 4; color: dashboard.language === modelData ? "#1f6053" : "#f3f6f5"; border.color: "#dce6e2" }
                    contentItem: Text { text: parent.text; color: dashboard.language === modelData ? "white" : "#5b6c71"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; font.pixelSize: 9 }
                    onClicked: dashboard.setLanguage(modelData)
                }
            }
        }
    }

    Flickable {
        id: contentView
        anchors.left: sidebar.right; anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 67; anchors.bottom: parent.bottom
        clip: true; contentWidth: width; contentHeight: page.implicitHeight + 60
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: page
            width: parent.width - 40
            x: 20
            topPadding: 38
            spacing: 22

            Row {
                width: parent.width; height: 58
                Row { spacing: 11
                    Rectangle { width: 40; height: 40; radius: 9; color: dashboard.accentSoft
                        Text { anchors.centerIn: parent; text: dashboard.assetLogo; color: dashboard.accent; font.bold: true; font.pixelSize: 17 }
                    }
                    Column { spacing: 3
                        Row { spacing: 9
                            Text { text: dashboard.assetName; color: "#19252e"; font.family: "Georgia"; font.bold: true; font.pixelSize: 28 }
                            Rectangle { width: 52; height: 22; radius: 4; border.color: "#dbe1e0"; Text { anchors.centerIn: parent; text: dashboard.ticker; color: "#77848b"; font.pixelSize: 10 } }
                        }
                        Text { text: dashboard.market; color: "#7d878e"; font.pixelSize: 12 }
                    }
                }
                Item { width: parent.width - 720; height: 1 }
                Column { width: 180; spacing: 3
                    Text { text: root.t("period_observed"); color: "#8d969c"; font.pixelSize: 10 }
                    Text { text: dashboard.headline.start + "  —  " + dashboard.headline.end; color: "#2b3941"; font.bold: true; font.pixelSize: 12 }
                    Text { text: dashboard.headline.sessions + " " + root.t("common_sessions"); color: "#7d878e"; font.pixelSize: 10 }
                }
            }

            Rectangle {
                width: parent.width; height: 156; radius: 10; color: "white"; border.color: "#e5e9e8"
                Row { anchors.fill: parent
                    Rectangle { width: parent.width * .4; height: parent.height; radius: 9; color: "#f0f7f3"
                        Column { anchors.left: parent.left; anchors.leftMargin: 23; anchors.verticalCenter: parent.verticalCenter; spacing: 7
                            Text { text: root.t("asset_performance"); color: "#778088"; font.pixelSize: 10; font.letterSpacing: 1 }
                            Text { text: dashboard.headline.asset_return; color: dashboard.accent; font.family: "Georgia"; font.bold: true; font.pixelSize: 38 }
                            Text { text: root.t("base_100_start"); color: "#60736c"; font.pixelSize: 11 }
                        }
                    }
                    Repeater { model: [
                        { label: "S&P 500 (SPY)", value: dashboard.headline.sp500_return, caption: root.t("same_period") },
                        { label: root.t("gap_asset_market"), value: dashboard.headline.difference, caption: root.t("outperformance") }
                    ]
                        delegate: Rectangle { required property var modelData; width: parent.width * .3; height: parent.height; border.color: "#e5e9e8"
                            Column { anchors.left: parent.left; anchors.leftMargin: 21; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                                Text { text: modelData.label; color: "#778088"; font.pixelSize: 10; font.letterSpacing: 1 }
                                Text { text: modelData.value; color: modelData.value.indexOf("-") >= 0 ? "#d66f67" : "#19252e"; font.family: "Georgia"; font.bold: true; font.pixelSize: 27 }
                                Text { text: modelData.caption; color: "#8b9398"; font.pixelSize: 10; wrapMode: Text.WordWrap; width: 190 }
                            }
                        }
                    }
                }
            }

            SectionTitle { eyebrow: root.t("comparison"); title: root.t("cumulative_performance") }
            Rectangle {
                width: parent.width; height: 315; radius: 9; color: "white"; border.color: "#e5e9e8"
                Row { anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 17; spacing: 18
                    Row { spacing: 5
                        Rectangle { width: 11; height: 3; color: dashboard.accent; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: dashboard.ticker; color: "#56656d"; font.pixelSize: 10 }
                    }
                    Row { spacing: 5
                        Rectangle { width: 11; height: 3; color: "#566f9c"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "S&P 500 (SPY)"; color: "#56656d"; font.pixelSize: 10 }
                    }
                    Text { text: root.t("base_100"); color: "#99a1a5"; font.pixelSize: 10 }
                }
                Canvas {
                    id: performanceCanvas
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                    anchors.margins: 18; anchors.topMargin: 47
                    onPaint: {
                        var ctx = getContext("2d"), data = dashboard.chartData
                        ctx.clearRect(0, 0, width, height)
                        if (data.length < 2) return
                        var lo = data[0].asset, hi = data[0].asset
                        for (var i = 0; i < data.length; ++i) { lo = Math.min(lo, data[i].asset, data[i].sp500); hi = Math.max(hi, data[i].asset, data[i].sp500) }
                        var padding = Math.max((hi - lo) * .08, 1); lo -= padding; hi += padding
                        for (var grid = 0; grid < 4; ++grid) { var gy = grid * height / 3; ctx.strokeStyle = "#eef1f0"; ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke() }
                        function line(key, color) {
                            ctx.strokeStyle = color; ctx.lineWidth = 2; ctx.beginPath()
                            for (var point = 0; point < data.length; ++point) { var x = point / (data.length - 1) * width; var y = (1 - (data[point][key] - lo) / (hi - lo)) * height; if (point) ctx.lineTo(x, y); else ctx.moveTo(x, y) }
                            ctx.stroke()
                        }
                        line("sp500", "#566f9c"); line("asset", dashboard.accent)
                    }
                    Connections { target: dashboard; function onChanged() { performanceCanvas.requestPaint() } }
                }
            }

            SectionTitle { eyebrow: root.t("valuation"); title: root.t("pe_title") }
            Rectangle {
                width: parent.width; height: 136; radius: 9; color: "white"; border.color: "#e5e9e8"
                Row {
                    anchors.fill: parent; anchors.margins: 1
                    Repeater {
                        model: [
                            { label: root.t("current_pe"), value: dashboard.valuation.current, caption: "" },
                            { label: root.t("median_pe"), value: dashboard.valuation.median, caption: root.t("period") },
                            { label: root.t("mean_pe"), value: dashboard.valuation.mean, caption: root.t("period") }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width / 3; height: parent.height; color: "transparent"; border.color: "#e5e9e8"
                            Column { anchors.left: parent.left; anchors.leftMargin: 21; anchors.verticalCenter: parent.verticalCenter; spacing: 7
                                Text { text: modelData.label; color: "#778088"; font.pixelSize: 10; font.letterSpacing: 1 }
                                Text { text: modelData.value; color: dashboard.accent; font.family: "Georgia"; font.bold: true; font.pixelSize: 29 }
                                Text { text: modelData.caption || (dashboard.valuation.observations + " " + root.t("pe_observations")); color: "#8b9398"; font.pixelSize: 10 }
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width; spacing: 18
                Rectangle { width: (parent.width - 18) * .56; height: 274; radius: 9; color: "white"; border.color: "#e5e9e8"
                    Column { anchors.fill: parent; anchors.margins: 20; spacing: 9
                        SectionTitle { width: parent.width; eyebrow: root.t("seasonality"); title: root.t("monthly_average") }
                        Row { width: parent.width; height: 117; spacing: 5
                            Repeater { model: dashboard.months
                                delegate: Column { required property var modelData; width: 33; height: 117; spacing: 3
                                    Item { width: parent.width; height: 96
                                        Rectangle { width: parent.width; height: 1; y: 48; color: "#e9eeee" }
                                        Rectangle { width: parent.width; height: Math.max(3, Math.abs(modelData.value) * 30); y: modelData.value >= 0 ? 48 - height : 48; radius: 2; color: modelData.value >= 0 ? "#70b39e" : "#e2a09a" }
                                    }
                                    Text { width: parent.width; text: modelData.label; horizontalAlignment: Text.AlignHCenter; color: "#899297"; font.pixelSize: 9 }
                                }
                            }
                        }
                        Text { text: root.t("best_month") + dashboard.bestMonth.label + " (" + dashboard.bestMonth.value + ", " + dashboard.bestMonth.observations + " " + root.t("sessions") + ")"; color: "#397766"; font.bold: true; font.pixelSize: 11 }
                        Text { text: root.t("monthly_note"); color: "#7d878e"; font.pixelSize: 10 }
                    }
                }
                Rectangle { width: (parent.width - 18) * .44; height: 274; radius: 9; color: "white"; border.color: "#e5e9e8"
                    Column { anchors.fill: parent; anchors.margins: 20; spacing: 12
                        SectionTitle { width: parent.width; eyebrow: root.t("weekly_rhythm"); title: root.t("daily_average") }
                        Repeater { model: dashboard.weekdays
                            delegate: Row { required property var modelData; width: parent.width; spacing: 8
                                Text { width: 63; text: modelData.label; color: "#7f898f"; font.pixelSize: 10 }
                                Rectangle { width: 182; height: 8; radius: 4; color: "#f0f2f2"; anchors.verticalCenter: parent.verticalCenter
                                    Rectangle { width: Math.min(parent.width, Math.abs(modelData.value) * 700); height: parent.height; radius: 4; color: modelData.value >= 0 ? "#73b9a1" : "#e4a19b" }
                                }
                                Text { text: modelData.value.toFixed(2) + " %"; color: "#526068"; font.pixelSize: 10 }
                            }
                        }
                        Text { text: root.t("best_day") + dashboard.bestWeekday.label + " (" + dashboard.bestWeekday.value + ", " + dashboard.bestWeekday.observations + " " + root.t("sessions") + ")"; color: "#397766"; font.bold: true; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: root.t("history_not_predictive"); color: "#7d878e"; font.pixelSize: 10 }
                    }
                }
            }

            SectionTitle { eyebrow: root.t("historical_exercises"); title: root.t("two_ways") }
            Row { width: parent.width; spacing: 18
                Repeater { model: dashboard.strategies
                    delegate: Rectangle { required property var modelData; width: (parent.width - 18) / 2; height: 184; radius: 9; color: "white"; border.color: "#e5e9e8"
                        Column { anchors.fill: parent; anchors.margins: 22; spacing: 8
                            Text { text: modelData.label.toUpperCase(); color: "#758189"; font.pixelSize: 10; font.letterSpacing: 1 }
                            Text { text: modelData.description; width: parent.width; color: "#34434b"; font.bold: true; font.pixelSize: 14; wrapMode: Text.WordWrap }
                            Row { spacing: 34
                                Column {
                                    Text { text: root.t("cumulative"); color: "#8d969c"; font.pixelSize: 9 }
                                    Text { text: modelData.value; color: modelData.value.indexOf("-") >= 0 ? "#d66f67" : dashboard.accent; font.family: "Georgia"; font.bold: true; font.pixelSize: 28 }
                                }
                                Column {
                                    Text { text: root.t("average_session"); color: "#8d969c"; font.pixelSize: 9 }
                                    Text { text: modelData.average; color: "#33424a"; font.bold: true; font.pixelSize: 17 }
                                }
                            }
                            Text { text: modelData.sessions + " " + root.t("sessions") + " · " + modelData.positive + " " + root.t("positive") + " · " + root.t("costs_excluded"); color: "#8b949a"; font.pixelSize: 10 }
                        }
                    }
                }
            }
            Rectangle { width: parent.width; height: 66; radius: 9; color: "#fff9ed"; border.color: "#f4e6c8"
                Text { anchors.fill: parent; anchors.margins: 16; text: root.t("reading"); wrapMode: Text.WordWrap; color: "#735c31"; font.pixelSize: 11 }
            }

            Item {
                id: correlationSection
                width: parent.width
                height: correlationContent.implicitHeight
                Column {
                    id: correlationContent
                    width: parent.width
                    spacing: 12
                    SectionTitle { eyebrow: root.t("correlations"); title: root.t("matrix_title") }
                    Rectangle {
                        id: matrixCard
                        property real cellWidth: Math.max(44, (width - 144 - dashboard.assets.length * 5) / Math.max(1, dashboard.assets.length))
                        width: parent.width; height: Math.max(330, 150 + dashboard.assets.length * 44); radius: 9; color: "white"; border.color: "#e5e9e8"
                        Column {
                            anchors.fill: parent; anchors.margins: 20; spacing: 8
                            Text { text: root.t("pearson"); color: "#637078"; font.pixelSize: 11 }
                            Row {
                                spacing: 5
                                Text { width: 104; text: "" }
                                Repeater {
                                    model: dashboard.assets
                                    delegate: Text { required property var modelData; width: matrixCard.cellWidth; text: modelData.ticker; horizontalAlignment: Text.AlignHCenter; color: "#6d787e"; font.bold: true; font.pixelSize: 9 }
                                }
                            }
                            Repeater {
                                model: dashboard.correlationMatrix
                                delegate: Row {
                                    required property var modelData
                                    height: 39; spacing: 5
                                    Text { width: 104; height: parent.height; text: modelData.ticker; verticalAlignment: Text.AlignVCenter; color: "#33424a"; font.bold: true; font.pixelSize: 11 }
                                    Repeater {
                                        model: modelData.cells
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: matrixCard.cellWidth; height: 39; radius: 4; color: modelData.color
                                            Text { anchors.centerIn: parent; text: modelData.value.toFixed(2); color: "#24353b"; font.bold: true; font.pixelSize: 11 }
                                        }
                                    }
                                }
                            }
                            Text { text: dashboard.correlationDataMode; color: "#8b949a"; font.pixelSize: 10 }
                            Text { text: root.t("correlation_note"); width: parent.width; color: "#7d878e"; font.pixelSize: 10; wrapMode: Text.WordWrap }
                        }
                    }
                }
            }
        }
    }
}
