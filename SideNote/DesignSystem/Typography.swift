import SwiftUI

/// DESIGN.md 字号梯度的唯一出处。
///
/// **M2 现状**：DESIGN.md 指定 PP Editorial New / General Sans / JetBrains Mono，
/// 但字体文件加载是 M3 polish 的任务。M2 用系统回退（serif=New York、
/// sans=系统、mono=系统等宽），但**字号 / 行距 / 字重严格照 DESIGN.md**。
/// M3 只需把下面三个 `family*` 改成 `.custom(...)`，其余调用点不动。
enum Typography {

    // 切到自定义字体时只改这三处（M3）。
    private static func display(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    private static func sans(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight)
    }
    private static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }

    // MARK: - Display (PP Editorial New)

    static let h1 = display(28, .regular)
    static let h2 = display(21, .regular)
    static let h3 = display(17, .medium)

    // MARK: - Body (General Sans)

    static let body       = sans(15, .regular)
    static let bodyBold   = sans(15, .semibold)
    static let listItem   = sans(13, .regular)
    static let button     = sans(13, .medium)
    static let meta       = sans(11, .regular)

    // MARK: - Mono (JetBrains Mono)

    static let codeBlock  = mono(13.5)
    static let inlineCode = mono(13)

    // MARK: - Leading helpers

    /// DESIGN.md 用 line-height 倍数；SwiftUI `.lineSpacing` 是「行间额外点数」。
    /// 换算：额外点数 ≈ fontSize × (multiple − 1)。
    static func lineSpacing(fontSize: CGFloat, multiple: CGFloat) -> CGFloat {
        max(0, fontSize * (multiple - 1))
    }

    static let bodyLineSpacing      = lineSpacing(fontSize: 15,   multiple: 1.55)
    static let listLineSpacing      = lineSpacing(fontSize: 13,   multiple: 1.45)
    static let codeBlockLineSpacing = lineSpacing(fontSize: 13.5, multiple: 1.5)
}
