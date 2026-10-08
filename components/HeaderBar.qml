import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HMIMI

Rectangle {
    id: root
    Layout.fillWidth: true
    height: 56
    color: Theme.headerBg
    radius: 8
    border.color: Theme.borderDark
    border.width: 1

    required property var controller

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 14

        RowLayout {
            spacing: 10

            Text {
                text: "HMI Telemetry"
                font.pixelSize: 14
                font.bold: true
                color: Theme.textPrimary
            }
        }

        Item { Layout.fillWidth: true }

        // Stat Summary Cards
        RowLayout {
            spacing: 8

            Rectangle {
                width: 105
                height: 38
                color: Theme.cardBg
                radius: 6
                border.color: Theme.borderDark
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    Text { text: "Peak Speed"; font.pixelSize: 9; color: Theme.textSecondary; Layout.alignment: Qt.AlignHCenter }
                    Text { text: root.controller.peakSpeed + " km/h"; font.pixelSize: 12; font.bold: true; color: Theme.textPrimary; Layout.alignment: Qt.AlignHCenter }
                }
            }

            Rectangle {
                width: 105
                height: 38
                color: Theme.cardBg
                radius: 6
                border.color: Theme.borderDark
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    Text { text: "Avg Speed"; font.pixelSize: 9; color: Theme.textSecondary; Layout.alignment: Qt.AlignHCenter }
                    Text { text: root.controller.avgSpeed + " km/h"; font.pixelSize: 12; font.bold: true; color: Theme.textPrimary; Layout.alignment: Qt.AlignHCenter }
                }
            }
        }
    }
}
