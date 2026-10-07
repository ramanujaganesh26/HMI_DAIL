import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 850
    height: 850
    minimumWidth: 500
    minimumHeight: 520
    visible: true
    title: qsTr("KM/H Precision Speedometer Dial")
    color: "#05070c"

    // Speed State - Default Starting at 0 KM/H
    property real speed: 0.0           // Default speed set to 0 KM/H (0 to 240)
    property real minSpeed: 0.0
    property real maxSpeed: 240.0

    // Root Focus Scope for Keyboard Navigation
    Item {
        id: rootItem
        anchors.fill: parent
        focus: true

        Component.onCompleted: rootItem.forceActiveFocus()

        // Keyboard Shortcuts Handler
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
                window.speed = Math.max(window.minSpeed, window.speed - 5);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
                window.speed = Math.min(window.maxSpeed, window.speed + 5);
                event.accepted = true;
            } else if (event.key === Qt.Key_PageUp) {
                window.speed = Math.min(window.maxSpeed, window.speed + 20);
                event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
                window.speed = Math.max(window.minSpeed, window.speed - 20);
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20

            // MAIN DIAL DISPLAY CONTAINER
            Item {
                id: dialContainer
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Outer Brushed Metallic Frame Ring
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) * 0.94
                    height: width
                    radius: width / 2
                    color: "#0a101d"
                    border.color: "#2c4466"
                    border.width: 5

                    // Inner High-Visibility Halo Ring
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.color: Qt.rgba(0, 0.94, 1, 0.35)
                        border.width: 2
                    }
                }

                // CANVAS DIAL RENDERER
                Canvas {
                    id: dialCanvas
                    anchors.fill: parent
                    antialiasing: true

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();

                        var cx = width / 2;
                        var cy = height / 2;
                        var radius = Math.min(width, height) * 0.38;

                        var startAngle = 0.75 * Math.PI; // 135 deg (bottom-left)
                        var endAngle = 2.25 * Math.PI;   // 405 deg (bottom-right, 270 deg span)
                        var totalAngle = endAngle - startAngle;

                        // 1. High-Contrast Background Arc Track
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, endAngle);
                        ctx.strokeStyle = "#1b2c45";
                        ctx.lineWidth = 16;
                        ctx.lineCap = "round";
                        ctx.stroke();

                        // 2. High-Speed Redline Warning Arc (180 to 240 KM/H)
                        var redlineStart = startAngle + (180.0 / 240.0) * totalAngle;
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, redlineStart, endAngle);
                        ctx.strokeStyle = "#ff1a53";
                        ctx.lineWidth = 18;
                        ctx.lineCap = "round";
                        ctx.stroke();

                        // 3. Dynamic Active Speed Arc Fill
                        var currentSpeed = window.speed;
                        var valPct = Math.max(0, Math.min(1.0, currentSpeed / window.maxSpeed));
                        var currentAngle = startAngle + valPct * totalAngle;

                        var activeColor = (currentSpeed >= 180) ? "#ff1a53" : "#00f0ff";

                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, currentAngle);
                        ctx.strokeStyle = activeColor;
                        ctx.lineWidth = 16;
                        ctx.lineCap = "round";
                        ctx.stroke();

                        // 4. High-Visibility Dial Scale Ticks and Clean Labels
                        ctx.font = "bold 15px Segoe UI, Arial, sans-serif";
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";

                        var numTicks = 12; // Ticks every 20 KM/H (0, 20, 40 ... 240)
                        for (var i = 0; i <= numTicks; i++) {
                            var pct = i / numTicks;
                            var ang = startAngle + pct * totalAngle;
                            var cosA = Math.cos(ang);
                            var sinA = Math.sin(ang);

                            var valNum = Math.round(pct * window.maxSpeed);

                            // Major Ticks
                            var innerR = radius - 20;
                            var outerR = radius - 4;
                            ctx.strokeStyle = (valNum >= 180) ? "#ff3562" : "#5b7da8";
                            ctx.lineWidth = 3.5;

                            ctx.beginPath();
                            ctx.moveTo(cx + innerR * cosA, cy + innerR * sinA);
                            ctx.lineTo(cx + outerR * cosA, cy + outerR * sinA);
                            ctx.stroke();

                            // Minor Sub-ticks
                            if (i < numTicks) {
                                for (var m = 1; m <= 3; m++) {
                                    var mAng = ang + (m / 4.0) * (totalAngle / numTicks);
                                    var mCos = Math.cos(mAng);
                                    var mSin = Math.sin(mAng);
                                    ctx.beginPath();
                                    ctx.moveTo(cx + (radius - 14) * mCos, cy + (radius - 14) * mSin);
                                    ctx.lineTo(cx + (radius - 4) * mCos, cy + (radius - 4) * mSin);
                                    ctx.lineWidth = 2;
                                    ctx.strokeStyle = "#2d4463";
                                    ctx.stroke();
                                }
                            }

                            // High-Visibility Label Placement
                            var textR = radius - 42;
                            ctx.fillStyle = (valNum >= 180) ? "#ff4d73" : "#ffffff";
                            ctx.fillText(valNum.toString(), cx + textR * cosA, cy + textR * sinA);
                        }

                        // 5. Sleek Tapered Glowing Needle
                        ctx.save();
                        ctx.translate(cx, cy);
                        ctx.rotate(currentAngle + Math.PI / 2);

                        ctx.shadowColor = activeColor;
                        ctx.shadowBlur = 15;

                        ctx.beginPath();
                        ctx.moveTo(-5, 24);
                        ctx.lineTo(-1.5, -radius + 6);
                        ctx.lineTo(1.5, -radius + 6);
                        ctx.lineTo(5, 24);
                        ctx.closePath();
                        ctx.fillStyle = activeColor;
                        ctx.fill();

                        ctx.restore();

                        // 6. Needle Pivot Hub Cap
                        ctx.beginPath();
                        ctx.arc(cx, cy, 28, 0, 2 * Math.PI);
                        ctx.fillStyle = "#0c1424";
                        ctx.fill();
                        ctx.lineWidth = 4;
                        ctx.strokeStyle = activeColor;
                        ctx.stroke();
                    }

                    Connections {
                        target: window
                        onSpeedChanged: dialCanvas.requestPaint()
                    }
                }

                // CLEAN CENTER DIGITAL SPEED POD
                Rectangle {
                    anchors.centerIn: parent
                    width: 155
                    height: 155
                    radius: 77.5
                    color: "#0c1524"
                    border.color: "#00f0ff"
                    border.width: 3

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            text: Math.round(window.speed).toString()
                            font.pixelSize: 60
                            font.bold: true
                            color: "#ffffff"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "KM/H"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            font.letterSpacing: 2
                            color: (window.speed >= 180) ? "#ff2a5f" : "#00f0ff"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            // SPEED PRESET BUTTONS (10, 30, 50, 70, 120, 180 KM/H)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Repeater {
                    model: [10, 30, 50, 70, 120, 180]
                    delegate: Rectangle {
                        width: 100
                        height: 44
                        radius: 10
                        color: Math.round(window.speed) === modelData ? "#00f0ff30" : "#111b2b"
                        border.color: Math.round(window.speed) === modelData ? "#00f0ff" : "#21334d"
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: modelData + " KM/H"
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 1
                            color: Math.round(window.speed) === modelData ? "#00f0ff" : "#b0cbef"
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.speed = modelData;
                                rootItem.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }
}
