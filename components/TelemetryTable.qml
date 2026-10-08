import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HMIMI

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    color: Theme.panelBg
    radius: 8
    border.color: Theme.borderDark
    border.width: 1

    required property var controller

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Telemetry Data Table"
                font.pixelSize: 12
                font.bold: true
                color: Theme.textPrimary
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "Latest 150 Log Entries"
                font.pixelSize: 10
                color: Theme.textSecondary
            }
        }

        // Column Headers
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: Theme.cardBg
            radius: 5
            border.color: Theme.borderDark
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Text { text: "# ID"; font.pixelSize: 10; font.bold: true; color: Theme.textSecondary; Layout.preferredWidth: 50 }
                Text { text: "TIMESTAMP"; font.pixelSize: 10; font.bold: true; color: Theme.textSecondary; Layout.preferredWidth: 90 }
                Text { text: "SPEED (KM/H)"; font.pixelSize: 10; font.bold: true; color: Theme.textSecondary; Layout.preferredWidth: 100 }
                Text { text: "ACCEL (m/s²)"; font.pixelSize: 10; font.bold: true; color: Theme.textSecondary; Layout.preferredWidth: 90 }
                Text { text: "VEHICLE STATUS"; font.pixelSize: 10; font.bold: true; color: Theme.textSecondary; Layout.fillWidth: true }
            }
        }

        // Data List View
        ListView {
            id: logListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.controller.telemetryModel
            clip: true
            spacing: 3

            delegate: Rectangle {
                width: logListView.width
                height: 32
                radius: 5
                color: (index % 2 === 0) ? "#ffffff" : "#f8fafc"
                border.color: (speed >= 180.0) ? "#dc262644" : "#e2e8f0"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        text: "#" + logId
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                        Layout.preferredWidth: 50
                    }

                    Text {
                        text: time
                        font.pixelSize: 10
                        color: Theme.textSecondary
                        Layout.preferredWidth: 90
                    }

                    Text {
                        text: speed + " km/h"
                        font.pixelSize: 11
                        font.bold: true
                        color: (speed >= 180.0) ? Theme.redlineAccent : Theme.textPrimary
                        Layout.preferredWidth: 100
                    }

                    Text {
                        text: (acceleration > 0 ? "+" : "") + acceleration.toFixed(1)
                        font.pixelSize: 10
                        font.bold: true
                        color: acceleration > 0 ? Theme.cyanAccent : (acceleration < 0 ? Theme.warningAmber : Theme.textMuted)
                        Layout.preferredWidth: 90
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 20
                            width: statusText.implicitWidth + 14
                            radius: 10
                            color: Qt.rgba(Qt.color(statusColor).r, Qt.color(statusColor).g, Qt.color(statusColor).b, 0.12)
                            border.color: statusColor
                            border.width: 1

                            Text {
                                id: statusText
                                anchors.centerIn: parent
                                text: status
                                font.pixelSize: 9
                                font.bold: true
                                color: statusColor
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                visible: root.controller.telemetryModel.count === 0
                color: "transparent"

                ColumnLayout {
                    spacing: 4
                    Text { text: "No telemetry data logged yet"; font.pixelSize: 12; color: Theme.textSecondary; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "Accelerate or use speed presets to log data"; font.pixelSize: 10; color: Theme.textMuted; Layout.alignment: Qt.AlignHCenter }
                }
            }

            ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }
        }
    }
}
