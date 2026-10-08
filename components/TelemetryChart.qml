import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HMIMI

Rectangle {
    id: root
    implicitWidth: 550
    implicitHeight: 330
    Layout.fillWidth: true
    Layout.fillHeight: true
    color: Theme.panelBg
    radius: 8
    border.color: Theme.borderDark
    border.width: 1

    required property var controller

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header Title Bar
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Speed Telemetry Graph (0 – 240 km/h)"
                font.pixelSize: 13
                font.bold: true
                color: Theme.textPrimary
            }

            Item { Layout.fillWidth: true }

            // Active Speed Badge
            Rectangle {
                height: 24
                width: liveSpeedText.implicitWidth + 14
                radius: 5
                color: (root.controller.speed >= 180.0) ? "#fef2f2" : "#f0f9ff"
                border.color: (root.controller.speed >= 180.0) ? Theme.redlineAccent : Theme.cyanAccent
                border.width: 1

                Text {
                    id: liveSpeedText
                    anchors.centerIn: parent
                    text: "Current: " + Math.round(root.controller.speed) + " km/h"
                    font.pixelSize: 11
                    font.bold: true
                    color: (root.controller.speed >= 180.0) ? Theme.redlineAccent : Theme.cyanAccent
                }
            }
        }

        // Canvas for Speed Graph (0 to 240 km/h vs. Time in seconds)
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

                var maxSpeed = root.controller.maxSpeed; // 240 km/h
                var history = root.controller.speedHistory;
                var n = (history && history.length >= 2) ? history.length : 0;

                // 1. Chart Background Fill & Border Frame
                ctx.fillStyle = "#ffffff";
                ctx.fillRect(paddingLeft, paddingTop, graphW, graphH);

                ctx.strokeStyle = "#cbd5e1";
                ctx.lineWidth = 1;
                ctx.strokeRect(paddingLeft, paddingTop, graphW, graphH);

                // 2. Y-Axis Title ("SPEED (KM/H)")
                ctx.save();
                ctx.translate(16, paddingTop + graphH / 2);
                ctx.rotate(-Math.PI / 2);
                ctx.font = "bold 10px Segoe UI, sans-serif";
                ctx.fillStyle = "#334155";
                ctx.textAlign = "center";
                ctx.fillText("SPEED (KM/H)", 0, 0);
                ctx.restore();

                // 3. Horizontal Grid Lines & Y-Axis Scale Ticks (0 to 240 km/h)
                ctx.font = "10px Segoe UI, sans-serif";
                ctx.fillStyle = "#475569";
                ctx.textAlign = "right";
                ctx.textBaseline = "middle";

                var speedSteps = [0, 40, 80, 120, 160, 200, 240];
                for (var s = 0; s < speedSteps.length; s++) {
                    var spdVal = speedSteps[s];
                    var y = paddingTop + graphH - (spdVal / maxSpeed) * graphH;

                    // Grid line
                    ctx.strokeStyle = (spdVal === 180) ? Qt.rgba(0.86, 0.15, 0.15, 0.4) : "#f1f5f9";
                    ctx.lineWidth = (spdVal === 180) ? 1.5 : 1;
                    if (spdVal === 180) ctx.setLineDash([4, 4]); else ctx.setLineDash([]);

                    ctx.beginPath();
                    ctx.moveTo(paddingLeft, y);
                    ctx.lineTo(paddingLeft + graphW, y);
                    ctx.stroke();
                    ctx.setLineDash([]);

                    // Y-Axis tick mark & label
                    ctx.beginPath();
                    ctx.moveTo(paddingLeft - 4, y);
                    ctx.lineTo(paddingLeft, y);
                    ctx.strokeStyle = "#94a3b8";
                    ctx.lineWidth = 1;
                    ctx.stroke();

                    ctx.fillText(spdVal.toString() + " km/h", paddingLeft - 7, y);
                }

                // Redline Threshold Annotation
                ctx.font = "bold 9px Segoe UI";
                ctx.fillStyle = "#dc2626";
                ctx.textAlign = "left";
                var redlineY = paddingTop + graphH - (180.0 / maxSpeed) * graphH;
                ctx.fillText("REDLINE (180 KM/H)", paddingLeft + 10, redlineY - 6);

                // 4. Vertical Grid Lines & X-Axis Time Ticks (-16s to 0s / Now)
                ctx.font = "10px Segoe UI, sans-serif";
                ctx.fillStyle = "#475569";
                ctx.textAlign = "center";
                ctx.textBaseline = "top";

                // History buffer contains up to 40 samples at 400ms = 16.0 seconds total time span
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

                    // Vertical gridline
                    ctx.strokeStyle = "#f1f5f9";
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(tx, paddingTop);
                    ctx.lineTo(tx, paddingTop + graphH);
                    ctx.stroke();

                    // X-Axis tick mark
                    ctx.strokeStyle = "#94a3b8";
                    ctx.beginPath();
                    ctx.moveTo(tx, paddingTop + graphH);
                    ctx.lineTo(tx, paddingTop + graphH + 4);
                    ctx.stroke();

                    // X-Axis tick label
                    ctx.fillStyle = (tObj.relSec === 0) ? "#0284c7" : "#475569";
                    ctx.fillText(tObj.label, tx, paddingTop + graphH + 7);
                }

                // Bottom X-Axis Title
                ctx.font = "bold 10px Segoe UI";
                ctx.fillStyle = "#1e293b";
                ctx.textAlign = "center";
                ctx.fillText("TIME ELAPSED (SECONDS)", paddingLeft + graphW / 2, h - 14);

                // 5. Plot Speed Curve & Area Gradient Fill
                if (n >= 2) {
                    var points = [];
                    for (var i = 0; i < n; i++) {
                        var px = paddingLeft + (i / (n - 1)) * graphW;
                        var py = paddingTop + graphH - (history[i] / maxSpeed) * graphH;
                        points.push({ x: px, y: py, val: history[i], idx: i });
                    }

                    // Gradient fill under speed curve
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

                    // Main speed curve stroke
                    ctx.beginPath();
                    ctx.moveTo(points[0].x, points[0].y);
                    for (var m = 1; m < points.length; m++) {
                        ctx.lineTo(points[m].x, points[m].y);
                    }
                    ctx.strokeStyle = "#0284c7";
                    ctx.lineWidth = 2.5;
                    ctx.stroke();

                    // Active pulse lead dot
                    var lastPt = points[points.length - 1];
                    ctx.beginPath();
                    ctx.arc(lastPt.x, lastPt.y, 5, 0, 2 * Math.PI);
                    ctx.fillStyle = (lastPt.val >= 180) ? "#dc2626" : "#0284c7";
                    ctx.fill();

                    // 6. Interactive Crosshair and Hover Tooltip
                    if (chartCanvas.isHovered && chartCanvas.hoverX >= paddingLeft && chartCanvas.hoverX <= paddingLeft + graphW) {
                        var hoverFrac = (chartCanvas.hoverX - paddingLeft) / graphW;
                        var closestIdx = Math.round(hoverFrac * (n - 1));
                        closestIdx = Math.max(0, Math.min(n - 1, closestIdx));

                        var pt = points[closestIdx];
                        var relTimeSec = ((closestIdx - (n - 1)) * 0.4).toFixed(1);

                        // Vertical Crosshair Line
                        ctx.strokeStyle = "#0284c7";
                        ctx.lineWidth = 1;
                        ctx.setLineDash([3, 3]);
                        ctx.beginPath();
                        ctx.moveTo(pt.x, paddingTop);
                        ctx.lineTo(pt.x, paddingTop + graphH);
                        ctx.stroke();
                        ctx.setLineDash([]);

                        // Data point highlight dot
                        ctx.beginPath();
                        ctx.arc(pt.x, pt.y, 6, 0, 2 * Math.PI);
                        ctx.fillStyle = "#0284c7";
                        ctx.fill();
                        ctx.strokeStyle = "#ffffff";
                        ctx.lineWidth = 2;
                        ctx.stroke();

                        // Tooltip Box
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
                target: root.controller
                onSpeedHistoryChanged: chartCanvas.requestPaint()
            }
        }
    }
}
