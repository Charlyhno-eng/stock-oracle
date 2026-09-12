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
                Text { anchors.left: parent.left; anchors.leftMargin: 13; anchors.verticalCenter: parent.verticalCenter; text: "▣   Analyse historique"; color: "#176f5a"; font.bold: true; font.pixelSize: 13 }
            }
            Item { width: 1; height: 13 }
            Text { text: "ACTIONS DISPONIBLES"; color: "#8a9298"; font.pixelSize: 10; font.letterSpacing: 1 }
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
            Text { text: "PÉRIODE D’ÉTUDE"; color: "#8a9298"; font.pixelSize: 10; font.letterSpacing: 1 }
            Row {
                spacing: 6
                Repeater {
                    model: [3, 5, 10]
                    delegate: Button {
                        required property var modelData
                        width: 68; height: 33; text: modelData + " ans"
                        background: Rectangle { radius: 4; border.color: "#dce2e1"; color: dashboard.years === modelData ? "#1f6053" : "white" }
                        contentItem: Text { text: parent.text; color: dashboard.years === modelData ? "white" : "#6f7d83"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 11 }
                        onClicked: dashboard.setYears(modelData)
                    }
                }
            }
            Button {
                width: parent.width; height: 35
                text: "Voir la matrice de corrélation  ↓"
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
            Text { width: parent.width; text: "Constats historiques uniquement — pas une recommandation d’investissement."; color: "#a0a7aa"; font.pixelSize: 9; wrapMode: Text.WordWrap }
        }
    }

    Rectangle {
        anchors.left: sidebar.right; anchors.right: parent.right; anchors.top: parent.top
        height: 67; color: "white"; border.color: "#e5e9e8"
        Text { anchors.left: parent.left; anchors.leftMargin: 55; anchors.verticalCenter: parent.verticalCenter; text: "ANALYSE HISTORIQUE   /   " + dashboard.ticker; color: "#668179"; font.bold: true; font.pixelSize: 11 }
    }

    Flickable {
        id: contentView
        anchors.left: sidebar.right; anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 67; anchors.bottom: parent.bottom
        clip: true; contentWidth: width; contentHeight: page.implicitHeight + 60
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: page
            width: Math.min(parent.width - 92, 1120)
            x: Math.max(40, (parent.width - width) / 2)
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
                    Text { text: "PÉRIODE OBSERVÉE"; color: "#8d969c"; font.pixelSize: 10 }
                    Text { text: dashboard.headline.start + "  —  " + dashboard.headline.end; color: "#2b3941"; font.bold: true; font.pixelSize: 12 }
                    Text { text: dashboard.headline.sessions + " séances communes"; color: "#7d878e"; font.pixelSize: 10 }
                }
            }

            Rectangle {
                width: parent.width; height: 156; radius: 10; color: "white"; border.color: "#e5e9e8"
                Row { anchors.fill: parent
                    Rectangle { width: parent.width * .4; height: parent.height; radius: 9; color: "#f0f7f3"
                        Column { anchors.left: parent.left; anchors.leftMargin: 23; anchors.verticalCenter: parent.verticalCenter; spacing: 7
                            Text { text: "PERFORMANCE DE L’ACTION"; color: "#778088"; font.pixelSize: 10; font.letterSpacing: 1 }
                            Text { text: dashboard.headline.asset_return; color: dashboard.accent; font.family: "Georgia"; font.bold: true; font.pixelSize: 38 }
                            Text { text: "Base 100 au début de la période"; color: "#60736c"; font.pixelSize: 11 }
                        }
                    }
                    Repeater { model: [
                        { label: "S&P 500 (SPY)", value: dashboard.headline.sp500_return, caption: "performance sur la même période" },
                        { label: "ÉCART ACTION / S&P 500", value: dashboard.headline.difference, caption: "surperformance ou sous-performance" }
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

            SectionTitle { eyebrow: "COMPARAISON"; title: "Performance cumulée : action vs S&P 500" }
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
                    Text { text: "Base 100"; color: "#99a1a5"; font.pixelSize: 10 }
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

            Row {
                width: parent.width; spacing: 18
                Rectangle { width: (parent.width - 18) * .56; height: 274; radius: 9; color: "white"; border.color: "#e5e9e8"
                    Column { anchors.fill: parent; anchors.margins: 20; spacing: 9
                        SectionTitle { width: parent.width; eyebrow: "SAISONNALITÉ"; title: "Rendement moyen par mois" }
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
                        Text { text: "Meilleur mois observé : " + dashboard.bestMonth.label + " (" + dashboard.bestMonth.value + ", " + dashboard.bestMonth.observations + " séances)"; color: "#397766"; font.bold: true; font.pixelSize: 11 }
                        Text { text: "Moyenne des rendements quotidiens du mois, calculée sur l’historique disponible."; color: "#7d878e"; font.pixelSize: 10 }
                    }
                }
                Rectangle { width: (parent.width - 18) * .44; height: 274; radius: 9; color: "white"; border.color: "#e5e9e8"
                    Column { anchors.fill: parent; anchors.margins: 20; spacing: 12
                        SectionTitle { width: parent.width; eyebrow: "RYTHME HEBDOMADAIRE"; title: "Rendement moyen par jour" }
                        Repeater { model: dashboard.weekdays
                            delegate: Row { required property var modelData; width: parent.width; spacing: 8
                                Text { width: 63; text: modelData.label; color: "#7f898f"; font.pixelSize: 10 }
                                Rectangle { width: 182; height: 8; radius: 4; color: "#f0f2f2"; anchors.verticalCenter: parent.verticalCenter
                                    Rectangle { width: Math.min(parent.width, Math.abs(modelData.value) * 700); height: parent.height; radius: 4; color: modelData.value >= 0 ? "#73b9a1" : "#e4a19b" }
                                }
                                Text { text: modelData.value.toFixed(2) + " %"; color: "#526068"; font.pixelSize: 10 }
                            }
                        }
                        Text { text: "Meilleur jour observé : " + dashboard.bestWeekday.label + " (" + dashboard.bestWeekday.value + ", " + dashboard.bestWeekday.observations + " séances)"; color: "#397766"; font.bold: true; font.pixelSize: 10; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: "Un historique ne prédit pas le prochain jour."; color: "#7d878e"; font.pixelSize: 10 }
                    }
                }
            }

            SectionTitle { eyebrow: "EXERCICES HISTORIQUES"; title: "Deux façons de détenir l’action" }
            Row { width: parent.width; spacing: 18
                Repeater { model: dashboard.strategies
                    delegate: Rectangle { required property var modelData; width: (parent.width - 18) / 2; height: 184; radius: 9; color: "white"; border.color: "#e5e9e8"
                        Column { anchors.fill: parent; anchors.margins: 22; spacing: 8
                            Text { text: modelData.label.toUpperCase(); color: "#758189"; font.pixelSize: 10; font.letterSpacing: 1 }
                            Text { text: modelData.description; width: parent.width; color: "#34434b"; font.bold: true; font.pixelSize: 14; wrapMode: Text.WordWrap }
                            Row { spacing: 34
                                Column {
                                    Text { text: "PERFORMANCE CUMULÉE"; color: "#8d969c"; font.pixelSize: 9 }
                                    Text { text: modelData.value; color: modelData.value.indexOf("-") >= 0 ? "#d66f67" : dashboard.accent; font.family: "Georgia"; font.bold: true; font.pixelSize: 28 }
                                }
                                Column {
                                    Text { text: "MOYENNE / SÉANCE"; color: "#8d969c"; font.pixelSize: 9 }
                                    Text { text: modelData.average; color: "#33424a"; font.bold: true; font.pixelSize: 17 }
                                }
                            }
                            Text { text: modelData.sessions + " séances · " + modelData.positive + " positives · hors frais, fiscalité et slippage"; color: "#8b949a"; font.pixelSize: 10 }
                        }
                    }
                }
            }
            Rectangle { width: parent.width; height: 66; radius: 9; color: "#fff9ed"; border.color: "#f4e6c8"
                Text { anchors.fill: parent; anchors.margins: 16; text: "Lecture : les mois et jours affichés sont des constats descriptifs. Les performances des stratégies supposent une exécution exacte aux cours d’ouverture et de clôture, sans frais, taxes ni impact de marché."; wrapMode: Text.WordWrap; color: "#735c31"; font.pixelSize: 11 }
            }

            Item {
                id: correlationSection
                width: parent.width
                height: correlationContent.implicitHeight
                Column {
                    id: correlationContent
                    width: parent.width
                    spacing: 12
                    SectionTitle { eyebrow: "CORRÉLATIONS"; title: "Matrice des actions disponibles" }
                    Rectangle {
                        width: parent.width; height: 430; radius: 9; color: "white"; border.color: "#e5e9e8"
                        Column {
                            anchors.fill: parent; anchors.margins: 20; spacing: 8
                            Text { text: "Corrélation de Pearson entre les rendements journaliers des titres."; color: "#637078"; font.pixelSize: 11 }
                            Row {
                                spacing: 5
                                Text { width: 104; text: "" }
                                Repeater {
                                    model: dashboard.assets
                                    delegate: Text { required property var modelData; width: 92; text: modelData.ticker; horizontalAlignment: Text.AlignHCenter; color: "#6d787e"; font.bold: true; font.pixelSize: 9 }
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
                                            width: 92; height: 39; radius: 4; color: modelData.color
                                            Text { anchors.centerIn: parent; text: modelData.value.toFixed(2); color: "#24353b"; font.bold: true; font.pixelSize: 11 }
                                        }
                                    }
                                }
                            }
                            Text { text: dashboard.correlationDataMode; color: "#8b949a"; font.pixelSize: 10 }
                            Text { text: "1 = mouvements très proches ; 0 = absence de relation linéaire ; −1 = évolutions opposées. Une corrélation ne prédit pas les rendements futurs."; width: parent.width; color: "#7d878e"; font.pixelSize: 10; wrapMode: Text.WordWrap }
                        }
                    }
                }
            }
        }
    }
}
