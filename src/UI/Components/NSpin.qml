// NSpin.qml - 加载指示器组件
import QtQuick
import QtQuick.Controls

Item {
    id: root

    // 属性定义
    property string size: "default"  // small, default, large
    property string tip: ""
    property bool spinning: true
    property real indicatorSize: {
        switch(size) {
            case "small": return 14;
            case "large": return 32;
            default: return 20;
        }
    }

    implicitWidth: indicatorSize
    implicitHeight: tip !== "" ? indicatorSize + tipText.height + 8 : indicatorSize

    // 旋转动画
    RotationAnimation on rotation {
        target: spinner
        running: root.spinning
        from: 0
        to: 360
        duration: 1000
        loops: Animation.Infinite
    }

    // 旋转图标
    Item {
        id: spinner
        width: root.indicatorSize
        height: root.indicatorSize
        anchors.horizontalCenter: parent.horizontalCenter

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                var centerX = width / 2;
                var centerY = height / 2;
                var radius = width / 2 - 2;

                ctx.clearRect(0, 0, width, height);

                for (var i = 0; i < 8; i++) {
                    ctx.beginPath();
                    var angle = (i * Math.PI) / 4;
                    var x1 = centerX + Math.cos(angle) * (radius - 4);
                    var y1 = centerY + Math.sin(angle) * (radius - 4);
                    var x2 = centerX + Math.cos(angle) * radius;
                    var y2 = centerY + Math.sin(angle) * radius;

                    ctx.moveTo(x1, y1);
                    ctx.lineTo(x2, y2);
                    ctx.strokeStyle = Theme.primary;
                    ctx.lineWidth = 2;
                    ctx.lineCap = "round";
                    ctx.globalAlpha = (i + 1) / 8;
                    ctx.stroke();
                }
            }
        }
    }

    // 提示文本
    Text {
        id: tipText
        visible: root.tip !== ""
        anchors {
            top: spinner.bottom
            topMargin: 8
            horizontalCenter: parent.horizontalCenter
        }
        text: root.tip
        font.pixelSize: 12
        color: Theme.textSecondary
    }
}
