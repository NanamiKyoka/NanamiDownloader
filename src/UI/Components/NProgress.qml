// NProgress.qml - Ant Design 风格进度条组件
import QtQuick
import QtQuick.Controls
import Nanami.UI 1.0

Item {
    id: root

    // 属性定义
    property real value: 0  // 0-100
    property real secondaryValue: 0  // 第二进度
    property string status: ""  // "", success, exception, active
    property string size: "default"  // small, default
    property string type: "line"  // line, circle
    property bool showInfo: true
    property bool indeterminate: false
    property string format: "%p%"  // 格式化字符串
    
    // 内部动画值
    property real animatedValue: value

    // 尺寸映射
    readonly property var sizeMap: ({
            "small": {
                lineHeight: 6,
                circleSize: 80
            },
            "default": {
                lineHeight: 8,
                circleSize: 120
            }
        })

    implicitWidth: type === "line" ? 200 : sizeMap[size].circleSize
    implicitHeight: type === "line" ? (showInfo ? 24 : sizeMap[size].lineHeight) : sizeMap[size].circleSize

    // 状态颜色
    readonly property color statusColor: {
        if (status === "success")
            return Theme.success;
        if (status === "exception")
            return Theme.error;
        return Theme.primary;
    }

    // 数值平滑过渡动画 - 使用 Theme 属性和硬编码默认值
    Behavior on animatedValue {
        enabled: !Theme || Theme.animationsEnabled
        NumberAnimation { duration: Theme ? Theme.durationNormal : 250; easing.type: Easing.OutCubic }
    }
    
    // 监听 value 变化
    onValueChanged: {
        var animationsEnabled = true
        if (Theme) {
            animationsEnabled = Theme.animationsEnabled
        }
        if (!animationsEnabled) {
            animatedValue = value
        }
    }

    // 线性进度条
    Rectangle {
        id: lineProgress
        visible: root.type === "line"
        anchors {
            left: parent.left
            right: showInfo ? infoText.left : parent.right
            rightMargin: showInfo ? 8 : 0
            verticalCenter: parent.verticalCenter
        }
        height: sizeMap[size].lineHeight
        radius: height / 2
        color: Theme.border

        // 进度填充
        Rectangle {
            id: progressFill
            width: indeterminate ? parent.width * 0.3 : parent.width * (root.animatedValue / 100)
            height: parent.height
            radius: height / 2
            color: statusColor
            
            // 宽度动画（当动画禁用时直接跳转）
            Behavior on width {
                enabled: false  // 由 animatedValue 的 Behavior 控制
            }

            // 动画
            SequentialAnimation on x {
                running: indeterminate
                loops: Animation.Infinite
                NumberAnimation {
                    from: -parent.width * 0.3
                    to: parent.width
                    duration: 1000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    from: parent.width
                    to: -parent.width * 0.3
                    duration: 0
                }
            }
        }

        // 第二进度
        Rectangle {
            id: secondaryProgress
            visible: secondaryValue > 0
            width: parent.width * (secondaryValue / 100)
            height: parent.height
            radius: height / 2
            color: statusColor
            opacity: 0.3
            
            // 第二进度动画 - 使用 Theme 属性和硬编码默认值
            Behavior on width {
                enabled: !Theme || Theme.animationsEnabled
                NumberAnimation { duration: Theme ? Theme.durationNormal : 250; easing.type: Easing.OutCubic }
            }
        }
    }

    // 进度信息
    Text {
        id: infoText
        visible: root.showInfo && root.type === "line"
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        text: format.replace("%p", Math.round(root.animatedValue).toString())
        font.pixelSize: 13
        color: Theme.textPrimary
    }

    // 圆形进度条
    Item {
        visible: root.type === "circle"
        anchors.fill: parent

        Canvas {
            id: circleCanvas
            anchors.fill: parent
            
            // 当 animatedValue 变化时重绘
            Connections {
                target: root
                function onAnimatedValueChanged() {
                    circleCanvas.requestPaint()
                }
            }
            
            onPaint: {
                var ctx = getContext("2d");
                var centerX = width / 2;
                var centerY = height / 2;
                // 确保 radius 为正数，最小值为 1
                var radius = Math.max(1, Math.min(centerX, centerY) - 5);

                ctx.clearRect(0, 0, width, height);

                // 背景圆环
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                ctx.strokeStyle = Theme.border;
                ctx.lineWidth = 6;
                ctx.stroke();

                // 进度圆环
                ctx.beginPath();
                var startAngle = -Math.PI / 2;
                var endAngle = startAngle + (2 * Math.PI * root.animatedValue / 100);
                ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                ctx.strokeStyle = statusColor;
                ctx.lineWidth = 6;
                ctx.lineCap = "round";
                ctx.stroke();
            }
        }

        // 中心文字
        Text {
            anchors.centerIn: parent
            text: format.replace("%p", Math.round(root.animatedValue).toString())
            font.pixelSize: 24
            font.bold: true
            color: statusColor
            visible: root.showInfo
        }
    }
}
