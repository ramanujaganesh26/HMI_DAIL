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
    property real speed: 0.0            // Current rendered speed (0 to 240 KM/H)
    property real maxSpeed: 240.0       // Maximum dial speed
    property bool isForwardPressed: false // True while forward key or pedal button is held down
    property string statusText: "IDLE (0 KM/H)"

    // Root Focus Scope for Keyboard Navigation
    Item {
        id: rootItem
        anchors.fill: parent
        focus: true

        Component.onCompleted: rootItem.forceActiveFocus()

        // Keyboard Event Handlers for Press & Release Forward Key
        Keys.onPressed: (event) => {
            // Forward Keys: UP ARROW, RIGHT ARROW, W, SPACEBAR, PAGE UP
            if (event.key === Qt.Key_Up || 
                event.key === Qt.Key_Right || 
                event.key === Qt.Key_W || 
                event.key === Qt.Key_Space || 
                event.key === Qt.Key_PageUp) {
                
                window.isForwardPressed = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Left || event.key === Qt.Key_S) {
                // Brake key: stop raising and slow down faster
                window.isForwardPressed = false;
                window.speed = Math.max(0, window.speed - 8.0);
                event.accepted = true;
            }
        }

        Keys.onReleased: (event) => {
            if (event.isAutoRepeat) return; // Ignore OS auto-repeat releases while key is held down

            if (event.key === Qt.Key_Up || 
                event.key === Qt.Key_Right || 
                event.key === Qt.Key_W || 
                event.key === Qt.Key_Space || 
                event.key === Qt.Key_PageUp) {
                
                // FORWARD KEY RELEASED -> Speed immediately comes down to 0 slowly
                window.isForwardPressed = false;
                event.accepted = true;
            }
        }

        // Speed Engine Loop (60 FPS Update)
        Timer {
            id: speedEngineTimer
            interval: 16 // 60 FPS update
            running: true
            repeat: true
            onTriggered: {
                if (window.isForwardPressed) {
                    // 1. FORWARD KEY IS PRESSED -> RAISE SPEED CONTINUOUSLY
                    if (window.speed < window.maxSpeed) {
                        window.speed = Math.min(window.maxSpeed, window.speed + 3.2); // Smooth acceleration (+200 KM/H in ~1.2 sec)
                    }
                    window.statusText = "🚀 RAISING SPEED (" + Math.round(window.speed) + " KM/H)";
                } else {
                    // 2. FORWARD KEY IS NOT PRESSED -> COME DOWN TO ZERO SLOWLY
                    if (window.speed > 0) {
                        // Smooth progressive deceleration (-30 KM/H per second)
                        var decayRate = Math.max(0.18, window.speed * 0.014 + 0.22);
                        window.speed = Math.max(0.0, window.speed - decayRate);
                        window.statusText = "📉 NOT PRESSING FORWARD KEY - COMING DOWN TO 0 KM/H";
                    } else {
                        window.speed = 0.0;
                        window.statusText = "IDLE (0 KM/H)";
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 18

            // TOP CONTROL & STATUS BAR
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                // FORWARD KEY INDICATOR
                Rectangle {
                    width: 240
                    height: 38
                    radius: 19
                    color: window.isForwardPressed ? "#00f0ff25" : "#141e2e"
                    border.color: window.isForwardPressed ? "#00f0ff" : "#2f4666"
                    border.width: 1.5

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: window.isForwardPressed ? "#00f0ff" : "#5a769e"
                        }

                        Text {
                            text: window.isForwardPressed ? "FORWARD KEY: HELD (RAISING)" : "FORWARD KEY: NOT PRESSED"
                            font.pixelSize: 11
                            font.bold: true
                            color: window.isForwardPressed ? "#00f0ff" : "#8eaad1"
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // LIVE STATUS BADGE
                Rectangle {
                    width: 330
                    height: 38
                    radius: 19
                    color: "#0a1324"
                    border.color: (window.speed > 0 && !window.isForwardPressed) ? "#ff9900" : "#00f0ff"
                    border.width: 1.5

                    Text {
                        anchors.centerIn: parent
                        text: window.statusText
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1
                        color: (window.speed > 0 && !window.isForwardPressed) ? "#ffb84d" : "#00f0ff"
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

            // FORWARD ACCELERATION PEDAL BUTTON (RAISES SPEED WHEN HELD, COMES DOWN WHEN RELEASED)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 440
                height: 56
                radius: 14
                color: pedalArea.pressed ? "#00f0ff40" : (window.isForwardPressed ? "#00f0ff25" : "#111f36")
                border.color: pedalArea.pressed || window.isForwardPressed ? "#00f0ff" : "#243a5c"
                border.width: 2.5

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "⬆️"
                        font.pixelSize: 20
                    }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: window.isForwardPressed ? "RAISING SPEED... (RELEASE TO COME DOWN)" : "HOLD FORWARD KEY (UP / W / SPACE / CLICK)"
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1
                            color: window.isForwardPressed ? "#00f0ff" : "#ffffff"
                        }
                        Text {
                            text: "Raises speed while held | Comes down to 0 slowly when released"
                            font.pixelSize: 10
                            color: "#8eaad1"
                        }
                    }
                }

                MouseArea {
                    id: pedalArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: {
                        window.isForwardPressed = true;
                        rootItem.forceActiveFocus();
                    }
                    onReleased: {
                        window.isForwardPressed = false; // RELEASED -> Comes down to 0 slowly
                        rootItem.forceActiveFocus();
                    }
                    onCanceled: {
                        window.isForwardPressed = false;
                        rootItem.forceActiveFocus();
                    }
                }
            }

            // TAP / HOLD PRESET SPEED RAISERS
            Text {
                text: "HOLD TO RAISE TO PRESET (RELEASE TO COME DOWN TO 0):"
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
                        color: presetArea.pressed ? "#00f0ff35" : "#111b2b"
                        border.color: presetArea.pressed ? "#00f0ff" : "#21334d"
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: modelData + " KM/H"
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1
                            color: presetArea.pressed ? "#00f0ff" : "#b0cbef"
                        }

                        MouseArea {
                            id: presetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: {
                                window.speed = modelData;
                                window.isForwardPressed = true; // Pressing preset boosts speed & raises
                                rootItem.forceActiveFocus();
                            }
                            onReleased: {
                                window.isForwardPressed = false; // Releasing preset immediately comes down to 0 slowly
                                rootItem.forceActiveFocus();
                            }
                            onCanceled: {
                                window.isForwardPressed = false;
                                rootItem.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }
}



