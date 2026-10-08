import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HMIMI

Rectangle {
    id: root
    Layout.fillWidth: true
    height: 72
    color: Theme.cardBg
    radius: 6
    border.color: Theme.borderDark
    border.width: 1

    required property var controller

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Text { text: "RPM & Gear"; font.pixelSize: 11; font.bold: true; color: Theme.textSecondary }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 24
                height: 18
                radius: 4
                color: "#e0f2fe"
                border.color: Theme.cyanAccent
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: root.controller.gear
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.cyanAccent
                }
            }
        }

        Text {
            text: Math.round(root.controller.rpm) + " <font size='1'>RPM</font>"
            textFormat: Text.RichText
            font.pixelSize: 16
            font.bold: true
            color: (root.controller.rpm >= 6000) ? Theme.redlineAccent : Theme.textPrimary
            Layout.alignment: Qt.AlignHCenter
        }

        // RPM Diagram Segmented Bar
        Canvas {
            id: rpmDiagramCanvas
            Layout.fillWidth: true
            height: 10
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var w = width;
                var h = height;
                var segments = 16;
                var gap = 3;
                var segW = (w - (segments - 1) * gap) / segments;

                var fillRatio = Math.min(1.0, root.controller.rpm / 8000.0);
                var activeSegs = Math.round(fillRatio * segments);

                for (var i = 0; i < segments; i++) {
                    var x = i * (segW + gap);
                    var isRedline = (i >= 12);
                    var isActive = (i < activeSegs);

                    ctx.fillStyle = isActive ? (isRedline ? "#dc2626" : "#0284c7") : "#cbd5e1";
                    ctx.beginPath();
                    ctx.roundRect(x, 0, segW, h, 2);
                    ctx.fill();
                }
            }

            Connections {
                target: root.controller
                onRpmChanged: rpmDiagramCanvas.requestPaint()
            }
        }
    }
}
