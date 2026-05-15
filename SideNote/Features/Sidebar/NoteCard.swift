import SwiftUI

/// 单条笔记卡片视图。严格照 DESIGN.md 规格。
///
/// 状态：
/// - normal: cardFill 半透明白底 + 1px hairline
/// - hover: cardFillHover + border 略深（120ms ease-out）
/// - selected: cardFillSelected + 左侧 2pt sage 立柱（inset shadow）
/// - pinned: 顶部左侧伸出一个 sage ceramic 图钉
struct NoteCard: View {

    let note: MockNote

    @State private var hovering = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // ---- 卡片主体 ----
            VStack(alignment: .leading, spacing: 6) {
                Text(note.title)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .tracking(-0.1)

                Text(note.preview)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.textMuted)
                    .lineLimit(2)
                    .lineSpacing(2)

                HStack(spacing: Spacing.sm) {
                    tagChip(note.tag)
                    Circle()
                        .fill(.textFaint)
                        .frame(width: 3, height: 3)
                    Text(note.timestamp)
                        .font(.system(size: 11))
                        .tracking(0.2)
                        .foregroundStyle(.textFaint)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay(cardBorder)
            .overlay(alignment: .leading) {
                if note.selected {
                    Rectangle()
                        .fill(.sage)
                        .frame(width: 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
            .onHover { hovering = $0 }
            .animation(.hover, value: hovering)

            // ---- 置顶图钉 ----
            if note.pinned {
                CeramicPin()
                    .offset(x: 14, y: -4)
            }
        }
    }

    private var cardBackground: Color {
        if note.selected { return .cardFillSelected }
        if hovering      { return .cardFillHover    }
        return .cardFill
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
            .stroke(hovering ? .hairline.opacity(1.4) : .hairline, lineWidth: BorderWidth.hairline)
    }

    private func tagChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .regular))
            .foregroundStyle(.textMuted)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.035))
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
    }
}

// MARK: - Ceramic pin

/// Sage 渐变陶瓷图钉。DESIGN.md spec:
/// - 12×18pt 头 + 2×16pt 针
/// - 整体 rotate 8°
/// - 渐变: sageDeep → sage → sageSoft → sage （模拟陶瓷高光）
struct CeramicPin: View {
    var body: some View {
        ZStack(alignment: .top) {
            // 针
            Rectangle()
                .fill(LinearGradient(
                    colors: [.sageDeep, .sage, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 2, height: 16)
                .offset(y: 10)

            // 头
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(LinearGradient(
                    colors: [.sageDeep, .sage, .sageSoft, .sage],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 12, height: 18)
                .overlay(
                    // 顶部高光
                    Capsule()
                        .fill(Color.white.opacity(0.30))
                        .frame(width: 5, height: 2)
                        .offset(y: -6)
                )
                .shadow(color: .black.opacity(0.20), radius: 1.5, y: 2)
        }
        .rotationEffect(.degrees(8))
        .frame(width: 14, height: 26)
    }
}
