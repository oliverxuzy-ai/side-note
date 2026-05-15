import SwiftUI

// MARK: - Color tokens
//
// 全部值来自 DESIGN.md。改这里 = 改设计系统，会影响所有使用方。
// 命名规则：避免和系统 .accent / .primary 冲突，sage 色加 `sage` 前缀。

extension Color {

    // canvas — sage-tinted near-white。v1 light 主背景。
    // M1 阶段：实际是 NSVisualEffectView vibrancy 之上的 92% 不透明叠层。
    static let canvas = Color(red: 0xF1 / 255.0, green: 0xF2 / 255.0, blue: 0xE9 / 255.0)

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
}

// MARK: - Motion tokens
//
// 北极星动作的关键参数。改这里要慎重 —— 这是品牌的"手感"。

extension Animation {

    /// Slide-in 内容 parallax spring。0.32s 时长，~0.22 弹性（≈ damping 0.78）。
    static let slideInContent = Animation.spring(duration: 0.32, bounce: 0.22)

    /// Slide-out 内容淡出。直接 100ms easeIn。
    static let slideOutContent = Animation.easeIn(duration: 0.10)

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

enum PanelGeometry {
    static let width:        CGFloat = 380
    static let height:       CGFloat = 720
    static let edgeMargin:   CGFloat = 20    // 与屏幕右边的间隙
    static let contentParallax: CGFloat = 12 // 内容相对面板的滑入位移
    static let contentDelay: Double = 0.08   // 内容在面板开始动后多久启动
}
