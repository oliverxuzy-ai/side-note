import SwiftUI

// MARK: - Color tokens
//
// 全部值来自 DESIGN.md。改这里 = 改设计系统，会影响所有使用方。
// 命名规则：避免和系统 .accent / .primary 冲突，sage 色加 `sage` 前缀。

extension Color {

    // canvas — sage-tinted near-white。保留作为 reference / 静态预览。
    // 注意：v1 实际渲染走 3-layer glass composition（见 SidebarPanelView），
    //       不再直接使用这个静态色当背景。
    static let canvas = Color(red: 0xF1 / 255.0, green: 0xF2 / 255.0, blue: 0xE9 / 255.0)

    // ---- Glass canvas composition (v1 light theme, see DESIGN.md) ----
    // Layer 2 of glass canvas: sage 染色层（@ opacity 0.12 in view）
    static let glassSageTint = Color(red: 0xC1 / 255.0, green: 0xC5 / 255.0, blue: 0xB0 / 255.0)
    // Layer 3 of glass canvas: warm white wash（@ opacity 0.45 in view）
    static let glassWarmWash = Color(red: 0xFF / 255.0, green: 0xFE / 255.0, blue: 0xFA / 255.0)

    // text
    static let textPrimary = Color(red: 0x1F / 255.0, green: 0x1E / 255.0, blue: 0x18 / 255.0)
    static let textMuted   = Color(red: 0x75 / 255.0, green: 0x72 / 255.0, blue: 0x6A / 255.0)
    static let textFaint   = Color(red: 0xA8 / 255.0, green: 0xA5 / 255.0, blue: 0x9C / 255.0)

    // sage accent (the only accent color in the system)
    static let sage     = Color(red: 0x6E / 255.0, green: 0x80 / 255.0, blue: 0x60 / 255.0)
    static let sageSoft = Color(red: 0xB8 / 255.0, green: 0xC2 / 255.0, blue: 0xA8 / 255.0)
    static let sageDeep = Color(red: 0x4F / 255.0, green: 0x5E / 255.0, blue: 0x45 / 255.0)

    // card surface (translucent white on top of canvas vibrancy)
    static let cardFill          = Color.white.opacity(0.55)
    static let cardFillHover     = Color.white.opacity(0.70)
    static let cardFillSelected  = Color.white.opacity(0.88)

    // borders & dividers (slightly tinted near-black)
    static let hairline  = Color(red: 0x1F / 255.0, green: 0x1E / 255.0, blue: 0x18 / 255.0).opacity(0.07)
    static let faintLine = Color(red: 0x1F / 255.0, green: 0x1E / 255.0, blue: 0x18 / 255.0).opacity(0.04)
}

// MARK: - ShapeStyle bridges
//
// 让 dot-syntax 在 `.fill(.sage)` / `.foregroundStyle(.textMuted)` 等 ShapeStyle context 里
// 工作。SwiftUI 的 dot-syntax 类型推断到的是 ShapeStyle 协议，不是 Color 类型 —— 所以
// `Color` 上的 static 属性它找不到。这层桥让两种写法都通。
extension ShapeStyle where Self == Color {
    static var canvas: Color           { Color.canvas }
    static var textPrimary: Color      { Color.textPrimary }
    static var textMuted: Color        { Color.textMuted }
    static var textFaint: Color        { Color.textFaint }
    static var sage: Color             { Color.sage }
    static var sageSoft: Color         { Color.sageSoft }
    static var sageDeep: Color         { Color.sageDeep }
    static var cardFill: Color         { Color.cardFill }
    static var cardFillHover: Color    { Color.cardFillHover }
    static var cardFillSelected: Color { Color.cardFillSelected }
    static var hairline: Color         { Color.hairline }
    static var faintLine: Color        { Color.faintLine }
    static var glassSageTint: Color    { Color.glassSageTint }
    static var glassWarmWash: Color    { Color.glassWarmWash }
}

// MARK: - Motion tokens
//
// 北极星动作的关键参数。改这里要慎重 —— 这是品牌的"手感"。

extension Animation {

    /// 北极星滑入动画：单一 spring 驱动整个 panel。0.42s + 0.22 弹性。
    /// 比之前的 0.32s 略长，配合 full glass 给"软着陆"感觉。
    static let slideIn = Animation.spring(duration: 0.42, bounce: 0.22)

    /// 滑出：果断离开。无弹性、稍快、ease-in（从静止加速离去）。
    static let slideOut = Animation.easeIn(duration: 0.22)

    /// Hover / 状态切换通用过渡。
    static let hover = Animation.easeOut(duration: 0.16)

    /// 按钮按下、图钉触发等微反馈。
    static let pressFeedback = Animation.spring(duration: 0.18, bounce: 0.14)
}

// MARK: - Numeric tokens

enum Spacing {
    static let xs2: CGFloat = 2
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 20
    static let xl:  CGFloat = 28
    static let xl2: CGFloat = 40
}

enum Radius {
    static let sm: CGFloat = 6   // 标签、chip
    static let md: CGFloat = 10  // 卡片、按钮、输入框
    static let lg: CGFloat = 14  // 设置面板、Sheet、窗口本身
}

enum BorderWidth {
    /// 卡片、输入框、容器轮廓。比标准 1pt 略粗，在 glass 背景上更稳定可见。
    static let hairline: CGFloat = 1.5
    /// 选中态左侧立柱、强调分隔线
    static let accent:   CGFloat = 2
}

enum PanelGeometry {
    /// 用户看到的"侧边栏"的可见宽度
    static let visibleWidth:  CGFloat = 380
    static let visibleHeight: CGFloat = 720
    /// 可见侧边栏与屏幕右边的间隙
    static let edgeMargin:    CGFloat = 20
    /// NSPanel 额外的"滑出缓冲区"——SwiftUI 把 surface offset 到这里 = 滑出屏幕外
    /// 必须 >= visibleWidth 才能让 surface 完全消失出 panel 视野
    static let slideBuffer:   CGFloat = 420

    /// NSPanel 总宽 = 可见宽 + 滑出缓冲区（用于把 surface 隐藏到 panel 右侧外）
    static var totalWidth:  CGFloat { visibleWidth + slideBuffer }
    static var totalHeight: CGFloat { visibleHeight }
}
