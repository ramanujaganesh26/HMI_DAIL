import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HMIMI

Item {
    id: root
    implicitWidth: 300
    implicitHeight: 240
    Layout.fillWidth: true
    Layout.fillHeight: true

    required property var controller

    // Outer Dial Ring Frame
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.94
        height: width
        radius: width / 2
        color: "#ffffff"
        border.color: "#334155"
        border.width: 4

        // Inner Sub-Halo Ring
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

    // Canvas Dial Renderer
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

            // 1. Background Arc Track
            ctx.beginPath();
            ctx.arc(cx, cy, radius, startAngle, endAngle);
            ctx.strokeStyle = "#0f172a";
            ctx.lineWidth = 12;
            ctx.lineCap = "round";
            ctx.stroke();

            // 2. Redline Arc (180 to 240 KM/H)
            var redlineStart = startAngle + (180.0 / 240.0) * totalAngle;
            ctx.beginPath();
            ctx.arc(cx, cy, radius, redlineStart, endAngle);
            ctx.strokeStyle = "#dc2626";
            ctx.lineWidth = 14;
            ctx.lineCap = "round";
            ctx.stroke();

            // 3. Dynamic Active Speed Arc Fill
            var currentSpeed = root.controller.speed;
            var valPct = Math.max(0, Math.min(1.0, currentSpeed / root.controller.maxSpeed));
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

            // 4. Scale Ticks and Labels (Dark Slate Text for 0-160, Red for 180-240)
            ctx.font = "bold 12px Segoe UI, sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";

            var numTicks = 12;
            for (var i = 0; i <= numTicks; i++) {
                var pct = i / numTicks;
                var ang = startAngle + pct * totalAngle;
                var cosA = Math.cos(ang);
                var sinA = Math.sin(ang);

                var valNum = Math.round(pct * root.controller.maxSpeed);

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
                ctx.fillStyle = (valNum >= 180) ? "#dc2626" : "#0f172a"; // Dark Slate text for 0 to 160!
                ctx.fillText(valNum.toString(), cx + textR * cosA, cy + textR * sinA);
            }

            // 5. Needle
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

            // 6. Center Hub Ring
            ctx.beginPath();
            ctx.arc(cx, cy, 22, 0, 2 * Math.PI);
            ctx.fillStyle = "#ffffff";
            ctx.fill();
            ctx.lineWidth = 3;
            ctx.strokeStyle = activeColor;
            ctx.stroke();
        }

        Connections {
            target: root.controller
            onSpeedChanged: dialCanvas.requestPaint()
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: root.controller.isAccelerating = true
            onReleased: root.controller.isAccelerating = false
            onCanceled: root.controller.isAccelerating = false
        }
    }

    // Center Digital Speed Pod
    Rectangle {
        anchors.centerIn: parent
        width: 125
        height: 125
        radius: 62.5
        color: "#ffffff"
        border.color: (root.controller.speed >= 180.0) ? Theme.redlineAccent : Theme.textPrimary
        border.width: 3

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            Text {
                text: Math.round(root.controller.speed).toString()
                font.pixelSize: 44
                font.bold: true
                color: Theme.textPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "KM/H"
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 2
                color: (root.controller.speed >= 180.0) ? Theme.redlineAccent : Theme.cyanAccent
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
