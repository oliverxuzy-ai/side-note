import SwiftUI

/// 复用的交互手感。DESIGN.md：motion 预算只投在有意义的状态变化上，
/// 不做装饰性动效；按下/hover/聚焦要"跟手"，spring 收尾不生硬。

/// 通用按压反馈：按下 0.97 缩 + 轻微变淡，松开 spring 弹回。
/// 用在所有图标/文字按钮（New note、header、冲突条…），替代 `.plain`。
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.72 : 1.0)
            .animation(.pressFeedback, value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

/// 主按钮（New note）：按下时连背景一起轻微下沉，更有实体感。
struct SagePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.pressFeedback, value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

/// hover 抬升：进入时轻微放大 + 阴影增强，spring 收尾。卡片/可点行用。
struct HoverLift: ViewModifier {
    @State private var hovering = false
    var lift: CGFloat = 1.012
    func body(content: Content) -> some View {
        content
            .scaleEffect(hovering ? lift : 1.0)
            .animation(.cardState, value: hovering)
            .onHover { hovering = $0 }
    }
}

extension View {
    func hoverLift(_ lift: CGFloat = 1.012) -> some View {
        modifier(HoverLift(lift: lift))
    }
}
