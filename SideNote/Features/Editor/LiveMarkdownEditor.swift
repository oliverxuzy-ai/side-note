import SwiftUI
import AppKit

// MARK: - AppKit font bridge (mirrors Typography fallback, but NSFont)

/// NSTextView 需要 NSFont（SwiftUI `Font` 用不了）。和 `Typography` 同一套
/// PostScript 名 + 优雅回退，只是返回 NSFont。
enum EditorFont {
    private static func named(_ ps: String, _ size: CGFloat) -> NSFont? {
        NSFont(name: ps, size: size)
    }
    static func body(_ s: CGFloat) -> NSFont {
        named("GeneralSans-Regular", s) ?? .systemFont(ofSize: s)
    }
    static func semibold(_ s: CGFloat) -> NSFont {
        named("GeneralSans-Semibold", s) ?? .systemFont(ofSize: s, weight: .semibold)
    }
    static func italic(_ s: CGFloat) -> NSFont {
        if let f = named("PPEditorialNew-Italic", s) { return f }
        return NSFontManager.shared.convert(.systemFont(ofSize: s), toHaveTrait: .italicFontMask)
    }
    static func display(_ s: CGFloat) -> NSFont {
        if let f = named("PPEditorialNew-Regular", s) { return f }
        let d = NSFont.systemFont(ofSize: s, weight: .regular).fontDescriptor
            .withDesign(.serif) ?? NSFont.systemFont(ofSize: s).fontDescriptor
        return NSFont(descriptor: d, size: s) ?? .systemFont(ofSize: s)
    }
    static func mono(_ s: CGFloat) -> NSFont {
        named("JetBrainsMono-Regular", s) ?? .monospacedSystemFont(ofSize: s, weight: .regular)
    }
}

// MARK: - Live Markdown editor (Bear-style: no mode switch)

/// 单一始终可编辑的文本视图。输入即渲染：标记符（`#` `**` `` ` `` `>` `[]()`）
/// **保留但变淡**，内容按 DESIGN.md 字体/色梯度即时上样式——不切 view/edit。
///
/// 实现：不改字符（只加属性），所以光标/选区/撤销天然不被打断；
/// 解析用按行 + 行内正则（对半成品 markdown 鲁棒，比 AST 重解析快）。
struct LiveMarkdownEditor: NSViewRepresentable {

    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        guard let tv = scroll.documentView as? NSTextView else { return scroll }

        tv.delegate = context.coordinator
        tv.textStorage?.delegate = context.coordinator
        tv.isRichText = false
        tv.allowsUndo = true
        tv.font = EditorFont.body(15)
        tv.textColor = NSColor(Color.textPrimary)
        tv.insertionPointColor = NSColor(Color.sage)
        tv.drawsBackground = false
        tv.textContainerInset = NSSize(width: 4, height: 8)
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.isAutomaticSpellingCorrectionEnabled = false
        tv.isContinuousSpellCheckingEnabled = false
        tv.string = text
        context.coordinator.highlight(tv.textStorage)

        scroll.drawsBackground = false
        scroll.backgroundColor = .clear
        scroll.hasVerticalScroller = true
        scroll.scrollerStyle = .overlay
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let tv = scroll.documentView as? NSTextView else { return }
        if tv.string != text && !context.coordinator.isEditing {
            let sel = tv.selectedRange()
            tv.string = text
            context.coordinator.highlight(tv.textStorage)
            tv.setSelectedRange(NSRange(location: min(sel.location, (text as NSString).length),
                                        length: 0))
        }
    }

    // MARK: - Coordinator / highlighter

    final class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        private let parent: LiveMarkdownEditor
        var isEditing = false

        init(_ parent: LiveMarkdownEditor) { self.parent = parent }

        func textDidChange(_ note: Notification) {
            guard let tv = note.object as? NSTextView else { return }
            isEditing = true
            parent.text = tv.string
            DispatchQueue.main.async { self.isEditing = false }
        }

        func textStorage(_ storage: NSTextStorage,
                          didProcessEditing edited: NSTextStorageEditActions,
                          range: NSRange, changeInLength delta: Int) {
            guard edited.contains(.editedCharacters) else { return }
            highlight(storage)
        }

        // MARK: Styling

        private var bodyColor:   NSColor { NSColor(Color.textPrimary) }
        private var fadedColor:  NSColor { NSColor(Color.textFaint) }
        private var mutedColor:  NSColor { NSColor(Color.textMuted) }
        private var linkColor:   NSColor { NSColor(Color.sageDeep) }
        private var accentSoft:  NSColor { NSColor(Color.sageSoft) }

        /// 全量重刷（笔记短，开销可忽略）。只改属性不改字符 → 选区/撤销不受影响。
        func highlight(_ storage: NSTextStorage?) {
            guard let storage else { return }
            let ns = storage.string as NSString
            let full = NSRange(location: 0, length: ns.length)
            guard full.length > 0 else { return }

            storage.beginEditing()
            // 1) reset 到正文基线
            storage.setAttributes([
                .font: EditorFont.body(15),
                .foregroundColor: bodyColor
            ], range: full)

            // 2) 按行：标题 / 引用 / 围栏代码
            var inFence = false
            ns.enumerateSubstrings(in: full, options: .byLines) { line, lineRange, _, _ in
                guard let line else { return }
                let t = line.trimmingCharacters(in: .whitespaces)

                if t.hasPrefix("```") {
                    inFence.toggle()
                    storage.addAttributes([.font: EditorFont.mono(13.5),
                                           .foregroundColor: self.fadedColor],
                                          range: lineRange)
                    return
                }
                if inFence {
                    storage.addAttributes([.font: EditorFont.mono(13.5)], range: lineRange)
                    return
                }
                if let m = Self.heading.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)) {
                    let hashes = (line as NSString).substring(with: m.range(at: 1)).count
                    let size: CGFloat = hashes == 1 ? 28 : (hashes == 2 ? 21 : 17)
                    storage.addAttribute(.font, value: EditorFont.display(size), range: lineRange)
                    // marker (#... + space) 变淡
                    let markerLen = hashes + 1
                    let mr = NSRange(location: lineRange.location,
                                     length: min(markerLen, lineRange.length))
                    storage.addAttribute(.foregroundColor, value: self.fadedColor, range: mr)
                    return
                }
                if t.hasPrefix(">") {
                    storage.addAttribute(.foregroundColor, value: self.mutedColor, range: lineRange)
                    if let gt = line.firstIndex(of: ">") {
                        let off = line.distance(from: line.startIndex, to: gt)
                        storage.addAttribute(.foregroundColor, value: self.fadedColor,
                                             range: NSRange(location: lineRange.location + off, length: 1))
                    }
                }
            }

            // 3) 行内：code / bold / italic / link（围栏内不重复上色）
            self.applyInline(Self.code,   storage, ns, full) { s, content, marker in
                s.addAttribute(.font, value: EditorFont.mono(13), range: content)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: marker.0)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: marker.1)
            }
            self.applyInline(Self.bold,   storage, ns, full) { s, content, marker in
                s.addAttribute(.font, value: EditorFont.semibold(15), range: content)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: marker.0)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: marker.1)
            }
            self.applyInline(Self.italic, storage, ns, full) { s, content, marker in
                s.addAttribute(.font, value: EditorFont.italic(15), range: content)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: marker.0)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: marker.1)
            }
            self.applyLink(storage, ns, full)

            storage.endEditing()
        }

        /// marker = (开标记 range, 闭标记 range)；content = 中间内容 range
        private func applyInline(_ re: NSRegularExpression, _ s: NSTextStorage,
                                 _ ns: NSString, _ full: NSRange,
                                 _ style: (NSTextStorage, NSRange, (NSRange, NSRange)) -> Void) {
            for m in re.matches(in: ns as String, range: full) {
                guard m.numberOfRanges >= 2 else { continue }
                let whole = m.range(at: 0)
                let content = m.range(at: 1)
                let openLen = content.location - whole.location
                let open = NSRange(location: whole.location, length: openLen)
                let close = NSRange(location: content.location + content.length,
                                    length: whole.location + whole.length
                                            - (content.location + content.length))
                style(s, content, (open, close))
            }
        }

        private func applyLink(_ s: NSTextStorage, _ ns: NSString, _ full: NSRange) {
            for m in Self.link.matches(in: ns as String, range: full) {
                guard m.numberOfRanges >= 3 else { continue }
                let whole = m.range(at: 0)
                let label = m.range(at: 1)
                s.addAttribute(.foregroundColor, value: linkColor, range: label)
                s.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: label)
                s.addAttribute(.underlineColor, value: accentSoft, range: label)
                // [ ] ( url ) 这些符号 + url 变淡
                let preLen = label.location - whole.location          // "["
                s.addAttribute(.foregroundColor, value: fadedColor,
                               range: NSRange(location: whole.location, length: preLen))
                let tailLoc = label.location + label.length
                s.addAttribute(.foregroundColor, value: fadedColor,
                               range: NSRange(location: tailLoc,
                                              length: whole.location + whole.length - tailLoc))
            }
        }

        // 行内正则（捕获组 1 = 内容）
        static let heading = try! NSRegularExpression(pattern: "^(#{1,6})\\s")
        static let code    = try! NSRegularExpression(pattern: "`([^`\\n]+)`")
        static let bold    = try! NSRegularExpression(pattern: "\\*\\*([^*\\n]+)\\*\\*")
        static let italic  = try! NSRegularExpression(pattern: "(?<![\\*_])[\\*_]([^\\*_\\n]+)[\\*_](?![\\*_])")
        static let link    = try! NSRegularExpression(pattern: "\\[([^\\]\\n]+)\\]\\(([^)\\n]+)\\)")
    }
}
