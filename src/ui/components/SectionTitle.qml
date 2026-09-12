import QtQuick

Item {
    required property string eyebrow
    required property string title
    implicitHeight: 51
    width: parent ? parent.width : 500
    Column {
        anchors.left: parent.left; anchors.bottom: parent.bottom; spacing: 4
        Text { text: eyebrow; color: "#8b959a"; font.pixelSize: 10; font.letterSpacing: 1.2 }
        Text { text: title; color: "#19252e"; font.family: "Georgia"; font.bold: true; font.pixelSize: 22 }
    }
}
