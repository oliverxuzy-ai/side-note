import SwiftUI

/// 单条笔记卡片视图。严格照 DESIGN.md 规格。
///
/// 状态：
/// - normal: cardFill 半透明白底 + hairline
/// - hover: cardFillHover + border 略深（120ms ease-out）
/// - selected: cardFillSelected + 左侧 2pt sage 立柱
/// - pinned: 左下角一个小 sage 图钉 icon
struct NoteCard: View {

    let note: NoteFile
    var selected: Bool = false

    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.displayTitle)
                .font(Typography.h3)
                .foregroundStyle(.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .tracking(-0.1)

            if !note.preview.isEmpty {
                Text(note.preview)
                    .font(Typography.listItem)
                    .foregroundStyle(.textMuted)
                    .lineLimit(2)
                    .lineSpacing(2)
            }

            HStack(spacing: Spacing.sm) {
                if note.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.sage)
                        .rotationEffect(.degrees(-40))
                }
                if let tag = note.tags.first {
                    tagChip(tag)
                    Circle()
                        .fill(.textFaint)
                        .frame(width: 3, height: 3)
                }
                Text(note.relativeTimestamp)
                    .font(Typography.meta)
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
            if selected {
                Rectangle()
                    .fill(.sage)
                    .frame(width: 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        // 选中态阴影微强（DESIGN.md：选中卡片「阴影微强」）
        .shadow(color: .black.opacity(selected ? 0.07 : 0.04),
                radius: selected ? 2 : 1, y: 1)
        .onHover { hovering = $0 }
        .animation(.cardState, value: hovering)   // 卡片 hover 120ms ease-out
        .animation(.cardState, value: selected)   // 选中切换 120ms ease-out
    }

    private var cardBackground: Color {
        if selected { return .cardFillSelected }
        if hovering  { return .cardFillHover    }
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
