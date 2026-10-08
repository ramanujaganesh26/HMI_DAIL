import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HMIMI

Popup {
    id: root
    anchors.centerIn: parent
    width: 640
    height: 500
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    required property var controller

    background: Rectangle {
        color: Theme.panelBg
        radius: 12
        border.color: Theme.cyanAccent
        border.width: 1.5
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "📋 TELEMETRY DATA SHEET EXPORTER (.CSV)"
                font.pixelSize: 14
                font.bold: true
                color: Theme.cyanAccent
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: closeBtnArea.pressed ? "#fee2e2" : Theme.cardBg
                Text { anchors.centerIn: parent; text: "✕"; color: Theme.textPrimary; font.bold: true }
                MouseArea {
                    id: closeBtnArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }

        Text {
            text: "Export telemetry log records into CSV spreadsheet format for Microsoft Excel, Google Sheets, or MATLAB:"
            font.pixelSize: 11
            color: Theme.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0f172a"
            radius: 8
            border.color: Theme.borderDark
            border.width: 1

            ScrollView {
                anchors.fill: parent
                anchors.margins: 10
                clip: true

                TextEdit {
                    id: csvArea
                    text: root.controller.exportCsvSheets()
                    font.family: "Consolas, Courier New, monospace"
                    font.pixelSize: 11
                    color: "#38bdf8"
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.NoWrap
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 150
                height: 34
                radius: 6
                color: copyBtn.pressed ? "#0284c733" : "#f0f9ff"
                border.color: Theme.cyanAccent
                border.width: 1

                Text {
                    id: copyBtnText
                    anchors.centerIn: parent
                    text: "📋 Copy Sheet Data"
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.cyanAccent
                }

                MouseArea {
                    id: copyBtn
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        csvArea.selectAll();
                        csvArea.copy();
                        copyBtnText.text = "✓ Copied to Clipboard!";
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 100
                height: 34
                radius: 6
                color: closePopBtn.pressed ? "#0284c733" : Theme.cardBg
                border.color: Theme.borderDark
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Close"
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.textPrimary
                }

                MouseArea {
                    id: closePopBtn
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }
    }
}
