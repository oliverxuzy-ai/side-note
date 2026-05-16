import SwiftUI

/// 复用的交互手感。DESIGN.md：motion 预算只投在有意义的状态变化上，
/// 不做装饰性动效；按下/hover/聚焦要"跟手"，spring 收尾不生硬。
///
/// hover 框用 **中性近黑低透明**（非 sage）——accent 在系统里稀有出现才被身体
/// 记住（DESIGN.md「Accent 只出现在 4 处」），按钮 hover 不能吃掉这个稀缺性。

/// 通用按压反馈：hover 时浮现一个克制的圆角框（让用户知道"鼠标在按钮上"），
/// 按下再加深 + 0.97 缩。用在所有图标/文字按钮（返回键、pin、New note、
/// 冲突条、搜索清除…），替代 `.plain`。
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var cornerRadius: CGFloat = Radius.sm
    var padding = EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)

    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration,
             scale: scale, cornerRadius: cornerRadius, padding: padding)
    }

    struct StyledLabel: View {
        let configuration: ButtonStyleConfiguration
        let scale: CGFloat
        let cornerRadius: CGFloat
        let padding: EdgeInsets
        @State private var hovering = false

        private var fill: Double {
            if configuration.isPressed { return 0.10 }
            return hovering ? 0.06 : 0
        }

        var body: some View {
            configuration.label
                .padding(padding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.textPrimary.opacity(fill))
                )
                .scaleEffect(configuration.isPressed ? scale : 1.0)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius,
                                               style: .continuous))
                .onHover { hovering = $0 }
                .animation(.cardState, value: hovering)
                .animation(.pressFeedback, value: configuration.isPressed)
        }
    }
}

/// 主按钮（New note）：hover 微提亮 + 轻抬，按下连背景一起下沉。
struct SagePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration)
    }

    struct StyledLabel: View {
        let configuration: ButtonStyleConfiguration
        @State private var hovering = false

        var body: some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.96 : (hovering ? 1.02 : 1.0))
                .brightness(configuration.isPressed ? -0.04 : (hovering ? 0.05 : 0))
                .contentShape(Rectangle())
                .onHover { hovering = $0 }
                .animation(.cardState, value: hovering)
                .animation(.pressFeedback, value: configuration.isPressed)
        }
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
