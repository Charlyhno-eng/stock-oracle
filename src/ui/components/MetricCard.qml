import QtQuick

Rectangle {
    required property string label
    required property string detail
    required property string value
    required property string caption
    color: "white"
    radius: 7
    border.color: "#e5e9e8"
    implicitHeight: 103
    Column {
        anchors.fill: parent; anchors.margins: 14; spacing: 5
        Text { text: label + "  " + detail; color: "#7b858c"; font.pixelSize: 10; font.letterSpacing: 1 }
        Text { text: value; color: "#1d6857"; font.family: "Georgia"; font.bold: true; font.pixelSize: 23 }
        Text { text: caption; color: "#899298"; font.pixelSize: 10 }
    }
}
