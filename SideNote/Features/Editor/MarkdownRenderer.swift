import SwiftUI
import Markdown

/// 把 Markdown 源码渲染成 SwiftUI 视图。`swift-markdown` 出 AST，自写渲染层。
///
/// v1 子集（DESIGN.md 锁定 8 类）：H1-H3 / 段落 / 无序列表 / 有序列表 /
/// 行内 code / 代码块 / 引用块 / 粗体 & 斜体 / 链接。
/// 不支持的语法（图片、表格、任务列表…）**原样显示源码文本**，不报错。
struct MarkdownView: View {

    let markdown: String

    var body: some View {
        let document = Document(parsing: markdown)
        return VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(document.blockChildren.enumerated()), id: \.offset) { _, block in
                MarkdownBlock(block: block, indent: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tint(.sageDeep)
    }
}

// MARK: - Block dispatch

private struct MarkdownBlock: View {

    let block: Markup
    let indent: CGFloat

    var body: some View {
        switch block {

        case let h as Heading:
            Text(InlineRenderer.attributed(h, base: headingFont(h.level)))
                .lineSpacing(2)
                .padding(.top, h.level == 1 ? 2 : 6)

        case let p as Paragraph:
            Text(InlineRenderer.attributed(p, base: Typography.body))
                .foregroundStyle(.textPrimary)
                .lineSpacing(Typography.bodyLineSpacing)

        case let q as BlockQuote:
            quote(q)

        case let code as CodeBlock:
            CodeBlockView(code: code.code)

        case let ul as UnorderedList:
            list(Array(ul.listItems), ordered: false)

        case let ol as OrderedList:
            list(Array(ol.listItems), ordered: true)

        case is ThematicBreak:
            Rectangle().fill(.faintLine).frame(height: 1).padding(.vertical, 4)

        default:
            // 未支持块（表格 / 图片 / 任务列表…）→ 原样源码
            Text(block.format().trimmingCharacters(in: .whitespacesAndNewlines))
                .font(Typography.body)
                .foregroundStyle(.textMuted)
        }
    }

    // MARK: - Quote

    private func quote(_ q: BlockQuote) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 1)
                .fill(.sageSoft)
                .frame(width: 2)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(q.blockChildren.enumerated()), id: \.offset) { _, child in
                    if let p = child as? Paragraph {
                        Text(InlineRenderer.attributed(p, base: Typography.body))
                            .foregroundStyle(.textMuted)
                            .lineSpacing(Typography.bodyLineSpacing)
                    } else {
                        MarkdownBlock(block: child, indent: 0)
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Lists

    private func list(_ items: [ListItem], ordered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(ordered ? "\(idx + 1)." : "•")
                        .font(Typography.listItem)
                        .foregroundStyle(.sage)
                        .frame(minWidth: ordered ? 18 : 10, alignment: .leading)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(item.blockChildren.enumerated()), id: \.offset) { _, child in
                            if let p = child as? Paragraph {
                                Text(InlineRenderer.attributed(p, base: Typography.listItem))
                                    .foregroundStyle(.textPrimary)
                                    .lineSpacing(Typography.listLineSpacing)
                            } else {
                                MarkdownBlock(block: child, indent: 16)
                            }
                        }
                    }
                }
            }
        }
        .padding(.leading, indent)
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1:  return Typography.h1
        case 2:  return Typography.h2
        default: return Typography.h3
        }
    }
}

// MARK: - Code block

private struct CodeBlockView: View {
    let code: String

    var body: some View {
        Text(code.trimmingCharacters(in: .newlines))
            .font(Typography.codeBlock)
            .foregroundStyle(.textPrimary)
            .lineSpacing(Typography.codeBlockLineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .padding(10)
            .background(Color(red: 0x1F/255, green: 0x1E/255, blue: 0x18/255).opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Inline → AttributedString

enum InlineRenderer {

    /// 把一个含 inline 子节点的块（段落 / 标题…）拍平成带样式的 AttributedString。
    static func attributed(_ markup: Markup, base: Font) -> AttributedString {
        var out = AttributedString()
        for child in markup.children {
            out.append(render(child, base: base))
        }
        if out.runs.isEmpty {
            out = AttributedString(" ")
        }
        return out
    }

    private static func render(_ markup: Markup, base: Font) -> AttributedString {
        switch markup {

        case let t as Markdown.Text:
            var s = AttributedString(t.string)
            s.font = base
            return s

        case let s as Strong:
            var inner = concat(s, base: base)
            inner.font = base.weight(.semibold)
            return inner

        case let e as Emphasis:
            var inner = concat(e, base: base)
            inner.font = base.italic()
            return inner

        case let c as InlineCode:
            var s = AttributedString(c.code)
            s.font = Typography.inlineCode
            s.foregroundColor = .textPrimary
            s.backgroundColor = Color(
                red: 0x1F/255, green: 0x1E/255, blue: 0x18/255
            ).opacity(0.05)
            return s

        case let link as Markdown.Link:
            var inner = concat(link, base: base)
            if let dest = link.destination, let url = URL(string: dest) {
                inner.link = url
            }
            inner.foregroundColor = .sageDeep
            inner.underlineStyle = .single
            return inner

        case is SoftBreak:
            return AttributedString(" ")

        case is LineBreak:
            return AttributedString("\n")

        case let img as Markdown.Image:
            // 未支持 → 原样源码文本
            var s = AttributedString(img.format())
            s.font = base
            s.foregroundColor = .textMuted
            return s

        default:
            // 其他 inline：递归取文本
            if markup.childCount > 0 {
                return concat(markup, base: base)
            }
            var s = AttributedString(markup.format())
            s.font = base
            return s
        }
    }

    private static func concat(_ markup: Markup, base: Font) -> AttributedString {
        var out = AttributedString()
        for child in markup.children {
            out.append(render(child, base: base))
        }
        return out
    }
}
