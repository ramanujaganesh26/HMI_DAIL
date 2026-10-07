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
    property bool isForwardPressed: false // True while key or preset button is held down

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
                
                // RELEASED -> Speed immediately comes down to 0 slowly
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
                        window.speed = Math.min(window.maxSpeed, window.speed + 3.2);
                    }
                } else {
                    // 2. FORWARD KEY IS NOT PRESSED -> COME DOWN TO ZERO SLOWLY
                    if (window.speed > 0) {
                        var decayRate = Math.max(0.18, window.speed * 0.014 + 0.22);
                        window.speed = Math.max(0.0, window.speed - decayRate);
                    } else {
                        window.speed = 0.0;
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 25

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

                    // Dial MouseArea for Click/Hold acceleration directly on Dial
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: {
                            window.isForwardPressed = true;
                            rootItem.forceActiveFocus();
                        }
                        onReleased: {
                            window.isForwardPressed = false;
                            rootItem.forceActiveFocus();
                        }
                        onCanceled: {
                            window.isForwardPressed = false;
                            rootItem.forceActiveFocus();
                        }
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

            // CLEAN SPEED PRESET BUTTONS (30, 60, 90, 120, 160, 200 KM/H)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Repeater {
                    model: [30, 60, 90, 120, 160, 200]
                    delegate: Rectangle {
                        width: 100
                        height: 44
                        radius: 10
                        color: presetArea.pressed ? "#00f0ff35" : "#111b2b"
                        border.color: presetArea.pressed ? "#00f0ff" : "#21334d"
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: modelData + " KM/H"
                            font.pixelSize: 13
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
                                window.isForwardPressed = true;
                                rootItem.forceActiveFocus();
                            }
                            onReleased: {
                                window.isForwardPressed = false;
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




