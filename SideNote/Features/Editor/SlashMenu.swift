import SwiftUI
import AppKit

// MARK: - Command model

/// 一条 slash 命令。`snippet` 写入文本；`caretOffset` 是插入后光标相对 snippet
/// 起点的位置（代码块要落在中间空行）。
struct SlashCommand: Identifiable {
    let id = UUID()
    let title: String
    let hint: String
    let glyph: String          // SF Symbol 名
    let keywords: [String]
    let snippet: String
    let caretOffset: Int

    static let all: [SlashCommand] = [
        .init(title: "Heading 1", hint: "Large section title",
              glyph: "textformat.size.larger", keywords: ["h1", "heading", "title"],
              snippet: "# ", caretOffset: 2),
        .init(title: "Heading 2", hint: "Medium section title",
              glyph: "textformat.size", keywords: ["h2", "heading"],
              snippet: "## ", caretOffset: 3),
        .init(title: "Heading 3", hint: "Small section title",
              glyph: "textformat.size.smaller", keywords: ["h3", "heading"],
              snippet: "### ", caretOffset: 4),
        .init(title: "Bullet list", hint: "Unordered list",
              glyph: "list.bullet", keywords: ["bullet", "ul", "list", "dash"],
              snippet: "- ", caretOffset: 2),
        .init(title: "To-do", hint: "Checkable task",
              glyph: "checklist", keywords: ["todo", "task", "checkbox", "check"],
              snippet: "- [ ] ", caretOffset: 6),
        .init(title: "Numbered list", hint: "Ordered list",
              glyph: "list.number", keywords: ["number", "ol", "ordered", "list"],
              snippet: "1. ", caretOffset: 3),
        .init(title: "Quote", hint: "Block quote",
              glyph: "text.quote", keywords: ["quote", "blockquote"],
              snippet: "> ", caretOffset: 2),
        .init(title: "Code block", hint: "Fenced monospace block",
              glyph: "curlybraces", keywords: ["code", "fence", "pre"],
              snippet: "```\n\n```", caretOffset: 4),
    ]

    static func filtered(_ q: String) -> [SlashCommand] {
        guard !q.isEmpty else { return all }
        let needle = q.lowercased()
        return all.filter {
            $0.title.lowercased().contains(needle)
                || $0.keywords.contains { $0.hasPrefix(needle) }
        }
    }
}

// MARK: - Shared state

final class SlashMenuModel: ObservableObject {
    @Published var items: [SlashCommand] = SlashCommand.all
    @Published var selection = 0
}

// MARK: - SwiftUI menu

/// 按 DESIGN.md：半透明白卡 + hairline 边、选中行 sage 软底 + 左立柱。
private struct SlashRow: View {
    let cmd: SlashCommand
    let selected: Bool

    private var iconColor: Color { selected ? Color.sageDeep : Color.textMuted }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: cmd.glyph)
                .font(.system(size: 13))
                .frame(width: 18)
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(cmd.title)
                    .font(Typography.body)
                    .foregroundStyle(Color.textPrimary)
                Text(cmd.hint)
                    .font(Typography.meta)
                    .foregroundStyle(Color.textFaint)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selectionBackground)
        .contentShape(Rectangle())
    }

    @ViewBuilder private var selectionBackground: some View {
        if selected {
            ZStack(alignment: .leading) {
                Color.sageSoft.opacity(0.22)
                Rectangle().fill(Color.sage).frame(width: 2)
            }
        } else {
            Color.clear
        }
    }
}

private struct SlashMenuView: View {
    @ObservedObject var model: SlashMenuModel
    let onPick: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(model.items.enumerated()), id: \.element.id) { idx, cmd in
                SlashRow(cmd: cmd, selected: idx == model.selection)
                    .onTapGesture { onPick(idx) }
            }
        }
        .padding(.vertical, 5)
        .frame(width: 248)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        )
        .shadow(color: Color.textPrimary.opacity(0.12), radius: 12, y: 4)
    }
}

// MARK: - Controller (owns the floating panel + caret tracking)

/// 跟着光标的轻量浮层。文本视图始终保持第一响应者——方向键/回车/Esc 由
/// `NSTextViewDelegate.doCommandBy` 拦截后驱动这里，菜单本身不抢焦点。
final class SlashMenuController {

    private let model = SlashMenuModel()
    private var panel: NSPanel?
    private var menuHost: NSView?          // 留引用以便布局后量真实尺寸
    private weak var textView: NSTextView?
    private var slashLocation = 0          // '/' 在文本里的绝对位置

    var isVisible: Bool { panel != nil }

    // MARK: 文本变化时调用：决定开/更新/关

    func handleTextChange(_ tv: NSTextView) {
        let ns = tv.string as NSString
        let caret = tv.selectedRange().location
        guard caret <= ns.length, tv.selectedRange().length == 0 else { dismiss(); return }

        let lineRange = ns.lineRange(for: NSRange(location: max(0, caret - 1), length: 0))
        let lineStart = lineRange.location
        guard caret >= lineStart else { dismiss(); return }
        let prefix = ns.substring(with: NSRange(location: lineStart, length: caret - lineStart))

        // 行内最后一个 "/token"，且 '/' 处在行首或空白后；token 仅字母
        guard let m = Self.trigger.firstMatch(
            in: prefix, range: NSRange(location: 0, length: (prefix as NSString).length))
        else { dismiss(); return }

        let slashInLine = m.range(at: 1).location          // '/' 在 prefix 里的位置
        slashLocation = lineStart + slashInLine
        let query = (prefix as NSString).substring(with: m.range(at: 2))

        let hits = SlashCommand.filtered(query)
        guard !hits.isEmpty else { dismiss(); return }
        model.items = hits
        model.selection = min(model.selection, hits.count - 1)

        if panel == nil { present(in: tv) }
        else { reposition() }
    }

    // MARK: 键盘（来自 doCommandBy）

    func move(_ delta: Int) {
        guard !model.items.isEmpty else { return }
        let n = model.items.count
        model.selection = (model.selection + delta + n) % n
    }

    func confirm() {
        guard let tv = textView, model.items.indices.contains(model.selection) else {
            dismiss(); return
        }
        let cmd = model.items[model.selection]
        let caret = tv.selectedRange().location
        let replace = NSRange(location: slashLocation,
                              length: max(0, caret - slashLocation))
        guard tv.shouldChangeText(in: replace, replacementString: cmd.snippet) else {
            dismiss(); return
        }
        tv.textStorage?.replaceCharacters(in: replace, with: cmd.snippet)
        tv.setSelectedRange(NSRange(location: slashLocation + cmd.caretOffset, length: 0))
        tv.didChangeText()
        dismiss()
    }

    func dismiss() {
        guard let panel else { return }
        panel.parent?.removeChildWindow(panel)
        panel.orderOut(nil)
        self.panel = nil
        self.menuHost = nil
        model.selection = 0
    }

    // MARK: 浮层

    private func present(in tv: NSTextView) {
        textView = tv
        let host = NSHostingView(rootView: SlashMenuView(model: model) { [weak self] idx in
            self?.model.selection = idx
            self?.confirm()
        })
        // fittingSize 在视图入窗 + 布局前是 (0,0) → 面板会被建成 0×0 不可见。
        // 先给确定初值，入窗后强制布局再量真实尺寸（见 reposition）。
        host.sizingOptions = .intrinsicContentSize
        menuHost = host

        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 248, height: 320),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: true)
        p.isFloatingPanel = true
        p.level = .popUpMenu
        p.hasShadow = false
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hidesOnDeactivate = true
        p.contentView = host
        host.layoutSubtreeIfNeeded()       // 让 fittingSize 变有效
        panel = p
        reposition()
        // side-note 是后台 LSUIElement App：非 key 窗口 macOS 不渲染。主面板靠
        // makeKeyAndOrderFront 显示；slash 子面板挂成它的 child window → 随父
        // 一起显示（后台也可见）、跟随父移动，且永远在父之上。
        if let parent = tv.window {
            parent.addChildWindow(p, ordered: .above)
        } else {
            p.orderFront(nil)
        }
    }

    private func reposition() {
        guard let tv = textView, let panel,
              let lm = tv.layoutManager, let tc = tv.textContainer,
              let win = tv.window else { return }
        let g = lm.glyphIndexForCharacter(at: min(slashLocation, (tv.string as NSString).length))
        var rect = lm.boundingRect(forGlyphRange: NSRange(location: g, length: 1), in: tc)
        rect.origin.x += tv.textContainerInset.width
        rect.origin.y += tv.textContainerInset.height

        let inView = tv.convert(rect, to: nil)
        let onScreen = win.convertToScreen(inView)
        menuHost?.layoutSubtreeIfNeeded()
        var size = menuHost?.fittingSize ?? .zero
        if size.width < 1 || size.height < 1 {     // 布局尚未稳定时的兜底
            size = NSSize(width: 248, height: CGFloat(model.items.count) * 46 + 10)
        }
        // 落在该行下方 6pt（AppKit 坐标自下而上：行底 = onScreen.minY）
        var origin = NSPoint(x: onScreen.minX, y: onScreen.minY - size.height - 6)
        if let vis = win.screen?.visibleFrame, origin.y < vis.minY {
            origin.y = onScreen.maxY + 6     // 贴边时翻到行上方
        }
        panel.setContentSize(size)
        panel.setFrameOrigin(origin)
    }

    /// 行内最后一个 "/token"：组1 = "/"，组2 = 后续字母（可空）。
    /// internal（非 private）以便单测直接验证触发规则。
    static let trigger = try! NSRegularExpression(
        pattern: "(?:^|\\s)(/)([\\p{L}]*)$")
}
