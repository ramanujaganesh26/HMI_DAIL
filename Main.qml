import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 880
    height: 900
    minimumWidth: 550
    minimumHeight: 600
    visible: true
    title: qsTr("KM/H Precision Speedometer Dial")
    color: "#05070c"

    // Speed State
    property real speed: 0.0            // Current rendered speed (0 to 240)
    property real targetSpeed: 0.0      // Target raised speed
    property real minSpeed: 0.0
    property real maxSpeed: 240.0
    property bool autoReturnToZero: true
    property bool isAccelerating: false
    property string statusText: "IDLE (0 KM/H)"

    // Root Focus Scope for Keyboard Navigation
    Item {
        id: rootItem
        anchors.fill: parent
        focus: true

        Component.onCompleted: rootItem.forceActiveFocus()

        // Keyboard Event Handlers for Press & Release Acceleration
        Keys.onPressed: (event) => {
            if (event.isAutoRepeat) return;

            if (event.key === Qt.Key_Space || event.key === Qt.Key_Up || event.key === Qt.Key_Right) {
                window.isAccelerating = true;
                window.targetSpeed = Math.min(window.maxSpeed, window.speed + 70);
                if (window.targetSpeed < 50) window.targetSpeed = 160;
                event.accepted = true;
            } else if (event.key === Qt.Key_PageUp) {
                window.isAccelerating = true;
                window.targetSpeed = Math.min(window.maxSpeed, window.speed + 100);
                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) {
                window.isAccelerating = false;
                window.targetSpeed = Math.max(window.minSpeed, window.speed - 30);
                event.accepted = true;
            }
        }

        Keys.onReleased: (event) => {
            if (event.isAutoRepeat) return;

            if (event.key === Qt.Key_Space || event.key === Qt.Key_Up || event.key === Qt.Key_Right || event.key === Qt.Key_PageUp) {
                // RELEASED: Immediately start reducing speed towards 0 slowly
                window.isAccelerating = false;
                event.accepted = true;
            }
        }

        // Return to Zero / Smooth Deceleration Engine
        Timer {
            id: returnToZeroTimer
            interval: 16 // ~60 FPS update loop
            running: true
            repeat: true
            onTriggered: {
                if (window.isAccelerating) {
                    // Button Held: Ramp UP speed towards target
                    if (window.speed < window.targetSpeed) {
                        window.speed = Math.min(window.targetSpeed, window.speed + 4.0);
                        window.statusText = "RAISING VELOCITY (" + Math.round(window.speed) + " KM/H)";
                    } else {
                        window.speed = window.targetSpeed;
                        window.statusText = "RAISED SPEED AT MAX";
                    }
                } else if (window.autoReturnToZero && window.speed > 0) {
                    // Button Released: Reduce speed towards 0 slowly
                    // Natural exponential decay (approx 30 KM/H per second)
                    var decayRate = Math.max(0.18, window.speed * 0.014 + 0.22);
                    window.speed = Math.max(0.0, window.speed - decayRate);
                    window.targetSpeed = window.speed;
                    window.statusText = "RELEASED - SLOWLY REDUCING TO 0 KM/H";
                } else {
                    if (window.speed === 0) {
                        window.statusText = "IDLE (0 KM/H)";
                    } else {
                        window.statusText = "MANUAL SPEED HOLD";
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 18

            // TOP CONTROL BAR & AUTO-RETURN TOGGLE
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    width: 220
                    height: 36
                    radius: 18
                    color: window.autoReturnToZero ? "#00f0ff15" : "#1a2436"
                    border.color: window.autoReturnToZero ? "#00f0ff" : "#3b5275"
                    border.width: 1.5

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: window.autoReturnToZero ? "#00f0ff" : "#7a95b8"
                        }

                        Text {
                            text: window.autoReturnToZero ? "Auto-Return to 0: ON" : "Auto-Return to 0: OFF"
                            font.pixelSize: 12
                            font.bold: true
                            color: window.autoReturnToZero ? "#00f0ff" : "#a0b8d8"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            window.autoReturnToZero = !window.autoReturnToZero;
                            rootItem.forceActiveFocus();
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // STATUS BADGE
                Rectangle {
                    width: 280
                    height: 36
                    radius: 18
                    color: "#0a1324"
                    border.color: (window.speed > 0 && !window.isAccelerating) ? "#ff9900" : "#00f0ff"
                    border.width: 1.5

                    Text {
                        anchors.centerIn: parent
                        text: window.statusText
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1
                        color: (window.speed > 0 && !window.isAccelerating) ? "#ffb84d" : "#00f0ff"
                    }
                }
            }

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
                    width: 160
                    height: 160
                    radius: 80
                    color: "#0c1524"
                    border.color: (window.speed >= 180) ? "#ff1a53" : "#00f0ff"
                    border.width: 3

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            text: Math.round(window.speed).toString()
                            font.pixelSize: 58
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

            // PRESS & HOLD ACCELERATION BUTTON (RAISES VELOCITY ON PRESS, DECAYS TO 0 ON RELEASE)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 420
                height: 54
                radius: 14
                color: pedalArea.pressed ? "#00f0ff40" : (window.isAccelerating ? "#00f0ff25" : "#111f36")
                border.color: pedalArea.pressed || window.isAccelerating ? "#00f0ff" : "#243a5c"
                border.width: 2.5

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "🚀"
                        font.pixelSize: 18
                    }

                    Text {
                        text: pedalArea.pressed || window.isAccelerating ? "RAISING VELOCITY... (RELEASE TO DECAY)" : "HOLD TO RAISE VELOCITY (RELEASE -> DECAY TO 0)"
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1
                        color: pedalArea.pressed || window.isAccelerating ? "#00f0ff" : "#d0e4ff"
                    }
                }

                MouseArea {
                    id: pedalArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: {
                        window.isAccelerating = true;
                        window.targetSpeed = 240; // Raise target speed up to max while held
                        rootItem.forceActiveFocus();
                    }
                    onReleased: {
                        window.isAccelerating = false; // RELEASED: Immediately reduce speed towards zero slowly
                        rootItem.forceActiveFocus();
                    }
                    onCanceled: {
                        window.isAccelerating = false;
                        rootItem.forceActiveFocus();
                    }
                }
            }

            // PRESET RAISE VELOCITY BUTTONS (30, 60, 90, 120, 160, 200 KM/H)
            Text {
                text: "PRESS & HOLD PRESETS (RELEASE TO SLOWLY REDUCE TO 0):"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1
                color: "#6b8ab3"
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Repeater {
                    model: [30, 60, 90, 120, 160, 200]
                    delegate: Rectangle {
                        width: 95
                        height: 42
                        radius: 10
                        color: (presetArea.pressed || (window.isAccelerating && window.targetSpeed === modelData)) ? "#00f0ff35" : "#111b2b"
                        border.color: (presetArea.pressed || (window.isAccelerating && window.targetSpeed === modelData)) ? "#00f0ff" : "#21334d"
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: modelData + " KM/H"
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1
                            color: (presetArea.pressed || (window.isAccelerating && window.targetSpeed === modelData)) ? "#00f0ff" : "#b0cbef"
                        }

                        MouseArea {
                            id: presetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: {
                                window.isAccelerating = true;
                                window.targetSpeed = modelData;
                                rootItem.forceActiveFocus();
                            }
                            onReleased: {
                                window.isAccelerating = false; // RELEASED: Immediately reduce speed towards zero slowly
                                rootItem.forceActiveFocus();
                            }
                            onCanceled: {
                                window.isAccelerating = false;
                                rootItem.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }
}


