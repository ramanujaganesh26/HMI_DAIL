import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 1360
    height: 880
    minimumWidth: 1080
    minimumHeight: 700
    maximumWidth: 1920
    maximumHeight: 1200
    visible: true
    title: qsTr("HMI Telemetry")
    color: "#f8fafc"

    // Optional external C++ controller injection (uses default built-in controller if not provided)
    property var externalController: null
    readonly property var controller: (externalController !== null) ? externalController : defaultController

    // Standalone Physics & Telemetry Engine (Works out-of-the-box in any QML environment)
    QtObject {
        id: defaultController
        property real speed: 0.0
        readonly property real maxSpeed: 240.0
        property real rpm: 0.0
        property string gear: "P"
        property real acceleration: 0.0
        property bool isAccelerating: false
        property bool isBraking: false
        property real peakSpeed: 0.0
        property real avgSpeed: 0.0
        property real totalSpeedSum: 0.0
        property var speedHistory: []
        readonly property alias recordCount: logModel.count
        readonly property alias telemetryModel: logModel

        function applyPresetSpeed(preset) {
            speed = Math.min(maxSpeed, Math.max(0, preset));
            isAccelerating = false;
            updateRpmAndGear();
            sampleLog();
        }

        function brakeStep() {
            isAccelerating = false;
            speed = Math.max(0, speed - 8.0);
            updateRpmAndGear();
            sampleLog();
        }

        function clearLogs() {
            logModel.clear();
            speedHistory = [];
            peakSpeed = 0.0;
            avgSpeed = 0.0;
            totalSpeedSum = 0.0;
        }

        function updateRpmAndGear() {
            if (speed === 0.0) { gear = "P"; rpm = 0.0; }
            else if (speed <= 35) { gear = "1"; rpm = speed * 140 + 800; }
            else if (speed <= 70) { gear = "2"; rpm = (speed - 35) * 100 + 1800; }
            else if (speed <= 110) { gear = "3"; rpm = (speed - 70) * 85 + 2000; }
            else if (speed <= 150) { gear = "4"; rpm = (speed - 110) * 75 + 2200; }
            else if (speed <= 190) { gear = "5"; rpm = (speed - 150) * 65 + 2400; }
            else { gear = "6"; rpm = (speed - 190) * 60 + 2600; }
            rpm = Math.min(8000, rpm);
        }

        function sampleLog() {
            var spd = Math.round(speed * 10) / 10;
            if (spd > peakSpeed) peakSpeed = spd;
            totalSpeedSum += spd;
            avgSpeed = Math.round((totalSpeedSum / (logModel.count + 1)) * 10) / 10;

            var now = new Date();
            var timeStr = Qt.formatDateTime(now, "hh:mm:ss.zzz");
            var statusStr = isAccelerating ? "ACCELERATING" : (speed > 0 ? "IDLE / CRUISE" : "STOPPED");
            var statusClr = isAccelerating ? "#0284c7" : (speed > 0 ? "#16a34a" : "#64748b");

            logModel.insert(0, {
                "logId": logModel.count + 1,
                "time": timeStr,
                "speed": spd,
                "acceleration": Math.round(acceleration * 10) / 10,
                "status": statusStr,
                "statusColor": statusClr
            });

            var hist = speedHistory.slice();
            hist.push(spd);
            if (hist.length > 40) hist.shift();
            speedHistory = hist;
        }
    }

    ListModel {
        id: logModel
    }

    Timer {
        interval: 16
        running: window.externalController === null
        repeat: true
        onTriggered: {
            if (defaultController.isAccelerating) {
                if (defaultController.speed < defaultController.maxSpeed) {
                    defaultController.speed = Math.min(defaultController.maxSpeed, defaultController.speed + 3.2);
                }
            } else {
                if (defaultController.speed > 0.0) {
                    var decay = Math.max(0.18, defaultController.speed * 0.014 + 0.22);
                    defaultController.speed = Math.max(0, defaultController.speed - decay);
                }
            }
            defaultController.updateRpmAndGear();
        }
    }

    Timer {
        interval: 400
        running: window.externalController === null
        repeat: true
        onTriggered: defaultController.sampleLog()
    }

    // Self-Contained Theme Palette Definition
    QtObject {
        id: theme
        readonly property color mainBg: "#f8fafc"
        readonly property color panelBg: "#ffffff"
        readonly property color cardBg: "#f1f5f9"
        readonly property color headerBg: "#ffffff"
        readonly property color cyanAccent: "#0284c7"
        readonly property color cyanGlow: "#06b6d4"
        readonly property color redlineAccent: "#dc2626"
        readonly property color warningAmber: "#d97706"
        readonly property color greenSuccess: "#16a34a"
        readonly property color textPrimary: "#0f172a"
        readonly property color textSecondary: "#475569"
        readonly property color textMuted: "#64748b"
        readonly property color borderDark: "#cbd5e1"
        readonly property color borderLight: "#e2e8f0"
    }

    // Key Handler Scope
    Item {
        id: rootItem
        anchors.fill: parent
        focus: true

        Component.onCompleted: rootItem.forceActiveFocus()

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Up || 
                event.key === Qt.Key_Right || 
                event.key === Qt.Key_W || 
                event.key === Qt.Key_Space || 
                event.key === Qt.Key_PageUp) {
                
                controller.isAccelerating = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Left || event.key === Qt.Key_S) {
                controller.brakeStep();
                event.accepted = true;
            }
        }

        Keys.onReleased: (event) => {
            if (event.isAutoRepeat) return;

            if (event.key === Qt.Key_Up || 
                event.key === Qt.Key_Right || 
                event.key === Qt.Key_W || 
                event.key === Qt.Key_Space || 
                event.key === Qt.Key_PageUp) {
                
                controller.isAccelerating = false;
                event.accepted = true;
            }
        }

        // ALL-IN-ONE WORKSTATION DASHBOARD LAYOUT
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // 1. TOP HEADER BAR
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: theme.headerBg
                radius: 8
                border.color: theme.borderDark
                border.width: 1

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
                            color: theme.textPrimary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Stat Summary Cards
                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 105
                            height: 38
                            color: theme.cardBg
                            radius: 6
                            border.color: theme.borderDark
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Text { text: "Peak Speed"; font.pixelSize: 9; color: theme.textSecondary; Layout.alignment: Qt.AlignHCenter }
                                Text { text: controller.peakSpeed + " km/h"; font.pixelSize: 12; font.bold: true; color: theme.textPrimary; Layout.alignment: Qt.AlignHCenter }
                            }
                        }

                        Rectangle {
                            width: 105
                            height: 38
                            color: theme.cardBg
                            radius: 6
                            border.color: theme.borderDark
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Text { text: "Avg Speed"; font.pixelSize: 9; color: theme.textSecondary; Layout.alignment: Qt.AlignHCenter }
                                Text { text: controller.avgSpeed + " km/h"; font.pixelSize: 12; font.bold: true; color: theme.textPrimary; Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }
                }
            }

            // 2. HERO ROW: INSTRUMENT CLUSTER (Left) & SPEED GRAPH (Right)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 340
                spacing: 10

                // CARD PANEL 1: SPEEDOMETER & RPM/GEAR CLUSTER
                Rectangle {
                    Layout.preferredWidth: 360
                    Layout.minimumWidth: 320
                    Layout.maximumWidth: 400
                    Layout.fillHeight: true
                    color: theme.panelBg
                    radius: 8
                    border.color: theme.borderDark
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Instrument Cluster"
                                font.pixelSize: 12
                                font.bold: true
                                color: theme.textPrimary
                            }
                        }

                        // SPEEDOMETER GAUGE DIAL
                        Item {
                            id: speedGaugeArea
                            implicitWidth: 300
                            implicitHeight: 240
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            // Outer Dial Ring Frame
                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) * 0.94
                                height: width
                                radius: width / 2
                                color: "#ffffff"
                                border.color: "#334155"
                                border.width: 4

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width - 14
                                    height: width
                                    radius: width / 2
                                    color: "transparent"
                                    border.color: Qt.rgba(0.02, 0.52, 0.78, 0.4)
                                    border.width: 1.5
                                }
                            }

                            Canvas {
                                id: dialCanvas
                                anchors.fill: parent
                                antialiasing: true

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();

                                    var cx = width / 2;
                                    var cy = height / 2;
                                    var radius = Math.min(width, height) * 0.36;

                                    var startAngle = 0.75 * Math.PI;
                                    var endAngle = 2.25 * Math.PI;
                                    var totalAngle = endAngle - startAngle;

                                    // Background Track
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, radius, startAngle, endAngle);
                                    ctx.strokeStyle = "#0f172a";
                                    ctx.lineWidth = 12;
                                    ctx.lineCap = "round";
                                    ctx.stroke();

                                    // Redline Arc (180 to 240 KM/H)
                                    var redlineStart = startAngle + (180.0 / 240.0) * totalAngle;
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, radius, redlineStart, endAngle);
                                    ctx.strokeStyle = "#dc2626";
                                    ctx.lineWidth = 14;
                                    ctx.lineCap = "round";
                                    ctx.stroke();

                                    // Dynamic Speed Arc Fill
                                    var currentSpeed = controller.speed;
                                    var valPct = Math.max(0, Math.min(1.0, currentSpeed / controller.maxSpeed));
                                    var currentAngle = startAngle + valPct * totalAngle;
                                    var activeColor = (currentSpeed >= 180.0) ? "#dc2626" : "#06b6d4";

                                    if (valPct > 0) {
                                        ctx.beginPath();
                                        ctx.arc(cx, cy, radius, startAngle, currentAngle);
                                        ctx.strokeStyle = activeColor;
                                        ctx.lineWidth = 12;
                                        ctx.lineCap = "round";
                                        ctx.stroke();
                                    }

                                    // Scale Ticks & Labels (0 to 240 KM/H)
                                    ctx.font = "bold 12px Segoe UI, sans-serif";
                                    ctx.textAlign = "center";
                                    ctx.textBaseline = "middle";

                                    var numTicks = 12;
                                    for (var i = 0; i <= numTicks; i++) {
                                        var pct = i / numTicks;
                                        var ang = startAngle + pct * totalAngle;
                                        var cosA = Math.cos(ang);
                                        var sinA = Math.sin(ang);
                                        var valNum = Math.round(pct * controller.maxSpeed);

                                        var innerR = radius - 14;
                                        var outerR = radius - 3;
                                        ctx.strokeStyle = (valNum >= 180) ? "#dc2626" : "#334155";
                                        ctx.lineWidth = 2.5;

                                        ctx.beginPath();
                                        ctx.moveTo(cx + innerR * cosA, cy + innerR * sinA);
                                        ctx.lineTo(cx + outerR * cosA, cy + outerR * sinA);
                                        ctx.stroke();

                                        if (i < numTicks) {
                                            for (var m = 1; m <= 3; m++) {
                                                var mAng = ang + (m / 4.0) * (totalAngle / numTicks);
                                                var mCos = Math.cos(mAng);
                                                var mSin = Math.sin(mAng);
                                                ctx.beginPath();
                                                ctx.moveTo(cx + (radius - 9) * mCos, cy + (radius - 9) * mSin);
                                                ctx.lineTo(cx + (radius - 3) * mCos, cy + (radius - 3) * mSin);
                                                ctx.lineWidth = 1.2;
                                                ctx.strokeStyle = "#64748b";
                                                ctx.stroke();
                                            }
                                        }

                                        var textR = radius - 30;
                                        ctx.fillStyle = (valNum >= 180) ? "#dc2626" : "#0f172a";
                                        ctx.fillText(valNum.toString(), cx + textR * cosA, cy + textR * sinA);
                                    }

                                    // Needle
                                    ctx.save();
                                    ctx.translate(cx, cy);
                                    ctx.rotate(currentAngle + Math.PI / 2);

                                    ctx.shadowColor = activeColor;
                                    ctx.shadowBlur = 10;

                                    ctx.beginPath();
                                    ctx.moveTo(-4, 18);
                                    ctx.lineTo(-1, -radius + 6);
                                    ctx.lineTo(1, -radius + 6);
                                    ctx.lineTo(4, 18);
                                    ctx.closePath();
                                    ctx.fillStyle = activeColor;
                                    ctx.fill();

                                    ctx.restore();

                                    // Center Hub Ring
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, 22, 0, 2 * Math.PI);
                                    ctx.fillStyle = "#ffffff";
                                    ctx.fill();
                                    ctx.lineWidth = 3;
                                    ctx.strokeStyle = activeColor;
                                    ctx.stroke();
                                }

                                Connections {
                                    target: controller
                                    onSpeedChanged: dialCanvas.requestPaint()
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: controller.isAccelerating = true
                                    onReleased: controller.isAccelerating = false
                                    onCanceled: controller.isAccelerating = false
                                }
                            }

                            // Center Digital Pod
                            Rectangle {
                                anchors.centerIn: parent
                                width: 125
                                height: 125
                                radius: 62.5
                                color: "#ffffff"
                                border.color: (controller.speed >= 180.0) ? theme.redlineAccent : theme.textPrimary
                                border.width: 3

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 0

                                    Text {
                                        text: Math.round(controller.speed).toString()
                                        font.pixelSize: 44
                                        font.bold: true
                                        color: theme.textPrimary
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: "KM/H"
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        font.letterSpacing: 2
                                        color: (controller.speed >= 180.0) ? theme.redlineAccent : theme.cyanGlow
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }

                        // RPM & GEAR WIDGET
                        Rectangle {
                            Layout.fillWidth: true
                            height: 72
                            color: theme.cardBg
                            radius: 6
                            border.color: theme.borderDark
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "RPM & Gear"; font.pixelSize: 11; font.bold: true; color: theme.textSecondary }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        width: 24
                                        height: 18
                                        radius: 4
                                        color: "#e0f2fe"
                                        border.color: theme.cyanAccent
                                        border.width: 1
                                        Text {
                                            anchors.centerIn: parent
                                            text: controller.gear
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: theme.cyanAccent
                                        }
                                    }
                                }

                                Text {
                                    text: Math.round(controller.rpm) + " <font size='1'>RPM</font>"
                                    textFormat: Text.RichText
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: (controller.rpm >= 6000) ? theme.redlineAccent : theme.textPrimary
                                    Layout.alignment: Qt.AlignHCenter
                                }

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

                                        var fillRatio = Math.min(1.0, controller.rpm / 8000.0);
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
                                        target: controller
                                        onRpmChanged: rpmDiagramCanvas.requestPaint()
                                    }
                                }
                            }
                        }
                    }
                }

                // CARD PANEL 2: SPEED TELEMETRY GRAPH
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 450
                    color: theme.panelBg
                    radius: 8
                    border.color: theme.borderDark
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Speed Telemetry Graph (0 – 240 km/h)"
                                font.pixelSize: 13
                                font.bold: true
                                color: theme.textPrimary
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                height: 24
                                width: liveSpeedText.implicitWidth + 14
                                radius: 5
                                color: (controller.speed >= 180.0) ? "#fef2f2" : "#f0f9ff"
                                border.color: (controller.speed >= 180.0) ? theme.redlineAccent : theme.cyanAccent
                                border.width: 1

                                Text {
                                    id: liveSpeedText
                                    anchors.centerIn: parent
                                    text: "Current: " + Math.round(controller.speed) + " km/h"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: (controller.speed >= 180.0) ? theme.redlineAccent : theme.cyanAccent
                                }
                            }
                        }

                        Canvas {
                            id: chartCanvas
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            antialiasing: true

                            property real hoverX: -1
                            property real hoverY: -1
                            property bool isHovered: false

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onPositionChanged: (mouse) => {
                                    chartCanvas.hoverX = mouse.x
                                    chartCanvas.hoverY = mouse.y
                                    chartCanvas.isHovered = true
                                    chartCanvas.requestPaint()
                                }
                                onExited: {
                                    chartCanvas.isHovered = false
                                    chartCanvas.requestPaint()
                                }
                            }

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();

                                var w = width;
                                var h = height;

                                var paddingLeft = 70;
                                var paddingRight = 25;
                                var paddingTop = 20;
                                var paddingBottom = 40;

                                var graphW = w - paddingLeft - paddingRight;
                                var graphH = h - paddingTop - paddingBottom;

                                if (graphW <= 0 || graphH <= 0) return;

                                var maxSpeed = controller.maxSpeed;
                                var history = controller.speedHistory;
                                var n = (history && history.length >= 2) ? history.length : 0;

                                // Chart Frame
                                ctx.fillStyle = "#ffffff";
                                ctx.fillRect(paddingLeft, paddingTop, graphW, graphH);
                                ctx.strokeStyle = "#cbd5e1";
                                ctx.lineWidth = 1;
                                ctx.strokeRect(paddingLeft, paddingTop, graphW, graphH);

                                // Y-Axis Title
                                ctx.save();
                                ctx.translate(16, paddingTop + graphH / 2);
                                ctx.rotate(-Math.PI / 2);
                                ctx.font = "bold 10px Segoe UI, sans-serif";
                                ctx.fillStyle = "#334155";
                                ctx.textAlign = "center";
                                ctx.fillText("SPEED (KM/H)", 0, 0);
                                ctx.restore();

                                // Y-Axis Grid & Ticks
                                ctx.font = "10px Segoe UI, sans-serif";
                                ctx.fillStyle = "#475569";
                                ctx.textAlign = "right";
                                ctx.textBaseline = "middle";

                                var speedSteps = [0, 40, 80, 120, 160, 200, 240];
                                for (var s = 0; s < speedSteps.length; s++) {
                                    var spdVal = speedSteps[s];
                                    var y = paddingTop + graphH - (spdVal / maxSpeed) * graphH;

                                    ctx.strokeStyle = (spdVal === 180) ? Qt.rgba(0.86, 0.15, 0.15, 0.4) : "#f1f5f9";
                                    ctx.lineWidth = (spdVal === 180) ? 1.5 : 1;
                                    if (spdVal === 180) ctx.setLineDash([4, 4]); else ctx.setLineDash([]);

                                    ctx.beginPath();
                                    ctx.moveTo(paddingLeft, y);
                                    ctx.lineTo(paddingLeft + graphW, y);
                                    ctx.stroke();
                                    ctx.setLineDash([]);

                                    ctx.beginPath();
                                    ctx.moveTo(paddingLeft - 4, y);
                                    ctx.lineTo(paddingLeft, y);
                                    ctx.strokeStyle = "#94a3b8";
                                    ctx.lineWidth = 1;
                                    ctx.stroke();

                                    ctx.fillText(spdVal.toString() + " km/h", paddingLeft - 7, y);
                                }

                                // Redline Label
                                ctx.font = "bold 9px Segoe UI";
                                ctx.fillStyle = "#dc2626";
                                ctx.textAlign = "left";
                                var redlineY = paddingTop + graphH - (180.0 / maxSpeed) * graphH;
                                ctx.fillText("REDLINE (180 KM/H)", paddingLeft + 10, redlineY - 6);

                                // X-Axis Time Ticks
                                ctx.font = "10px Segoe UI, sans-serif";
                                ctx.fillStyle = "#475569";
                                ctx.textAlign = "center";
                                ctx.textBaseline = "top";

                                var timeTicks = [
                                    { relSec: -16, label: "-16s" },
                                    { relSec: -12, label: "-12s" },
                                    { relSec: -8,  label: "-8s"  },
                                    { relSec: -4,  label: "-4s"  },
                                    { relSec:  0,  label: "0s (Now)" }
                                ];

                                for (var t = 0; t < timeTicks.length; t++) {
                                    var tObj = timeTicks[t];
                                    var fraction = (tObj.relSec + 16.0) / 16.0;
                                    var tx = paddingLeft + fraction * graphW;

                                    ctx.strokeStyle = "#f1f5f9";
                                    ctx.lineWidth = 1;
                                    ctx.beginPath();
                                    ctx.moveTo(tx, paddingTop);
                                    ctx.lineTo(tx, paddingTop + graphH);
                                    ctx.stroke();

                                    ctx.strokeStyle = "#94a3b8";
                                    ctx.beginPath();
                                    ctx.moveTo(tx, paddingTop + graphH);
                                    ctx.lineTo(tx, paddingTop + graphH + 4);
                                    ctx.stroke();

                                    ctx.fillStyle = (tObj.relSec === 0) ? "#0284c7" : "#475569";
                                    ctx.fillText(tObj.label, tx, paddingTop + graphH + 7);
                                }

                                ctx.font = "bold 10px Segoe UI";
                                ctx.fillStyle = "#1e293b";
                                ctx.textAlign = "center";
                                ctx.fillText("TIME ELAPSED (SECONDS)", paddingLeft + graphW / 2, h - 14);

                                // Speed Curve Plot
                                if (n >= 2) {
                                    var points = [];
                                    for (var i = 0; i < n; i++) {
                                        var px = paddingLeft + (i / (n - 1)) * graphW;
                                        var py = paddingTop + graphH - (history[i] / maxSpeed) * graphH;
                                        points.push({ x: px, y: py, val: history[i], idx: i });
                                    }

                                    var grad = ctx.createLinearGradient(0, paddingTop, 0, paddingTop + graphH);
                                    grad.addColorStop(0, Qt.rgba(0.01, 0.52, 0.78, 0.22));
                                    grad.addColorStop(1, Qt.rgba(0.01, 0.52, 0.78, 0.01));

                                    ctx.beginPath();
                                    ctx.moveTo(points[0].x, paddingTop + graphH);
                                    ctx.lineTo(points[0].x, points[0].y);
                                    for (var k = 1; k < points.length; k++) {
                                        ctx.lineTo(points[k].x, points[k].y);
                                    }
                                    ctx.lineTo(points[points.length - 1].x, paddingTop + graphH);
                                    ctx.closePath();
                                    ctx.fillStyle = grad;
                                    ctx.fill();

                                    ctx.beginPath();
                                    ctx.moveTo(points[0].x, points[0].y);
                                    for (var m = 1; m < points.length; m++) {
                                        ctx.lineTo(points[m].x, points[m].y);
                                    }
                                    ctx.strokeStyle = "#0284c7";
                                    ctx.lineWidth = 2.5;
                                    ctx.stroke();

                                    var lastPt = points[points.length - 1];
                                    ctx.beginPath();
                                    ctx.arc(lastPt.x, lastPt.y, 5, 0, 2 * Math.PI);
                                    ctx.fillStyle = (lastPt.val >= 180) ? "#dc2626" : "#0284c7";
                                    ctx.fill();

                                    // Hover Crosshair Tooltip
                                    if (chartCanvas.isHovered && chartCanvas.hoverX >= paddingLeft && chartCanvas.hoverX <= paddingLeft + graphW) {
                                        var hoverFrac = (chartCanvas.hoverX - paddingLeft) / graphW;
                                        var closestIdx = Math.round(hoverFrac * (n - 1));
                                        closestIdx = Math.max(0, Math.min(n - 1, closestIdx));

                                        var pt = points[closestIdx];
                                        var relTimeSec = ((closestIdx - (n - 1)) * 0.4).toFixed(1);

                                        ctx.strokeStyle = "#0284c7";
                                        ctx.lineWidth = 1;
                                        ctx.setLineDash([3, 3]);
                                        ctx.beginPath();
                                        ctx.moveTo(pt.x, paddingTop);
                                        ctx.lineTo(pt.x, paddingTop + graphH);
                                        ctx.stroke();
                                        ctx.setLineDash([]);

                                        ctx.beginPath();
                                        ctx.arc(pt.x, pt.y, 6, 0, 2 * Math.PI);
                                        ctx.fillStyle = "#0284c7";
                                        ctx.fill();
                                        ctx.strokeStyle = "#ffffff";
                                        ctx.lineWidth = 2;
                                        ctx.stroke();

                                        var tooltipText = "T: " + (relTimeSec >= 0 ? "+" : "") + relTimeSec + "s | " + pt.val.toFixed(1) + " km/h";
                                        ctx.font = "bold 11px Segoe UI";
                                        var textMetrics = ctx.measureText(tooltipText);
                                        var ttWidth = textMetrics.width + 16;
                                        var ttHeight = 22;

                                        var ttX = pt.x + 10;
                                        if (ttX + ttWidth > paddingLeft + graphW) ttX = pt.x - ttWidth - 10;
                                        var ttY = Math.max(paddingTop + 5, pt.y - 30);

                                        ctx.fillStyle = "#0f172a";
                                        ctx.beginPath();
                                        ctx.roundRect(ttX, ttY, ttWidth, ttHeight, 4);
                                        ctx.fill();

                                        ctx.fillStyle = "#ffffff";
                                        ctx.textAlign = "center";
                                        ctx.textBaseline = "middle";
                                        ctx.fillText(tooltipText, ttX + ttWidth / 2, ttY + ttHeight / 2);
                                    }

                                } else {
                                    ctx.fillStyle = "#64748b";
                                    ctx.font = "11px Segoe UI";
                                    ctx.textAlign = "center";
                                    ctx.fillText("Sampling speed telemetry...", paddingLeft + graphW / 2, paddingTop + graphH / 2);
                                }
                            }

                            Connections {
                                target: controller
                                onSpeedHistoryChanged: chartCanvas.requestPaint()
                            }
                        }
                    }
                }
            }

            // 3. TARGET SPEED PRESETS BAR
            Rectangle {
                Layout.fillWidth: true
                height: 42
                color: theme.panelBg
                radius: 8
                border.color: theme.borderDark
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Repeater {
                        model: [30, 60, 90, 120, 160, 200]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            radius: 5
                            color: presetArea.pressed ? "#0284c722" : theme.cardBg
                            border.color: presetArea.pressed ? theme.cyanAccent : theme.borderDark
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData + " km/h"
                                font.pixelSize: 11
                                font.bold: true
                                color: presetArea.pressed ? theme.cyanAccent : theme.textPrimary
                            }

                            MouseArea {
                                id: presetArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    controller.applyPresetSpeed(modelData);
                                    rootItem.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }

            // 4. CARD PANEL 3: HIGH-FREQUENCY TELEMETRY LOG DATA TABLE
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: theme.panelBg
                radius: 8
                border.color: theme.borderDark
                border.width: 1

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
                            color: theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Latest 150 Log Entries"
                            font.pixelSize: 10
                            color: theme.textSecondary
                        }
                    }

                    // Column Headers
                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        color: theme.cardBg
                        radius: 5
                        border.color: theme.borderDark
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text { text: "# ID"; font.pixelSize: 10; font.bold: true; color: theme.textSecondary; Layout.preferredWidth: 50 }
                            Text { text: "TIMESTAMP"; font.pixelSize: 10; font.bold: true; color: theme.textSecondary; Layout.preferredWidth: 90 }
                            Text { text: "SPEED (KM/H)"; font.pixelSize: 10; font.bold: true; color: theme.textSecondary; Layout.preferredWidth: 100 }
                            Text { text: "ACCEL (m/s²)"; font.pixelSize: 10; font.bold: true; color: theme.textSecondary; Layout.preferredWidth: 90 }
                            Text { text: "VEHICLE STATUS"; font.pixelSize: 10; font.bold: true; color: theme.textSecondary; Layout.fillWidth: true }
                        }
                    }

                    // Data List View
                    ListView {
                        id: logListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: controller.telemetryModel
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
                                    color: theme.textMuted
                                    Layout.preferredWidth: 50
                                }

                                Text {
                                    text: time
                                    font.pixelSize: 10
                                    color: theme.textSecondary
                                    Layout.preferredWidth: 90
                                }

                                Text {
                                    text: speed + " km/h"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: (speed >= 180.0) ? theme.redlineAccent : theme.textPrimary
                                    Layout.preferredWidth: 100
                                }

                                Text {
                                    text: (acceleration > 0 ? "+" : "") + acceleration.toFixed(1)
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: acceleration > 0 ? theme.cyanGlow : (acceleration < 0 ? theme.warningAmber : theme.textMuted)
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
                            visible: controller.telemetryModel.count === 0
                            color: "transparent"

                            ColumnLayout {
                                spacing: 4
                                Text { text: "No telemetry data logged yet"; font.pixelSize: 12; color: theme.textSecondary; Layout.alignment: Qt.AlignHCenter }
                                Text { text: "Accelerate or use speed presets to log data"; font.pixelSize: 10; color: theme.textMuted; Layout.alignment: Qt.AlignHCenter }
                            }
                        }

                        ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }
                    }
                }
            }
        }
    }
}
