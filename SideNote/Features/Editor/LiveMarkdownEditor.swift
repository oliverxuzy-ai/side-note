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

// MARK: - Custom attributes (drive glyph drawing)

extension NSAttributedString.Key {
    /// 标在 list marker（`-`/`*`/`+`）上 → layout manager 原位画 • 圆点。
    static let snBullet = NSAttributedString.Key("snBullet")
    /// 标在 `[ ]` / `[x]` 上，value = Bool（是否勾选）→ 画复选框。
    static let snCheckbox = NSAttributedString.Key("snCheckbox")
}

// MARK: - Layout manager that draws bullets / checkboxes

/// 原始标记字符在 highlighter 里被设成 `.clear`（隐形但仍占位、文本不变），
/// 这里在它们的位置上画真正的 • / ☐ / ☑。光标/撤销/选区完全不受影响。
final class MarkdownLayoutManager: NSLayoutManager {

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        guard let ts = textStorage, let tc = textContainers.first else { return }
        let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        ts.enumerateAttribute(.snBullet, in: charRange) { value, range, _ in
            guard value != nil else { return }
            let r = rect(for: range, container: tc, origin: origin)
            let d: CGFloat = 5
            let dot = NSRect(x: r.minX + 1,
                             y: r.midY - d / 2,
                             width: d, height: d)
            NSColor(Color.sage).setFill()
            NSBezierPath(ovalIn: dot).fill()
        }

        ts.enumerateAttribute(.snCheckbox, in: charRange) { value, range, _ in
            guard let checked = value as? Bool else { return }
            let r = rect(for: range, container: tc, origin: origin)
            let s: CGFloat = 13
            let box = NSRect(x: r.minX + 1, y: r.midY - s / 2, width: s, height: s)
            let path = NSBezierPath(roundedRect: box, xRadius: 3.5, yRadius: 3.5)
            path.lineWidth = 1.5
            if checked {
                NSColor(Color.sage).setFill(); path.fill()
                let tick = NSBezierPath()
                tick.move(to: NSPoint(x: box.minX + 3.0, y: box.midY + 0.3))
                tick.line(to: NSPoint(x: box.minX + 5.2, y: box.minY + 3.4))
                tick.line(to: NSPoint(x: box.maxX - 2.6, y: box.maxY - 3.0))
                tick.lineWidth = 1.6
                tick.lineCapStyle = .round
                tick.lineJoinStyle = .round
                NSColor.white.setStroke(); tick.stroke()
            } else {
                NSColor(Color.sageDeep).withAlphaComponent(0.65).setStroke()
                path.stroke()
            }
        }
    }

    private func rect(for charRange: NSRange, container: NSTextContainer, origin: NSPoint) -> NSRect {
        let gr = glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
        var r = boundingRect(forGlyphRange: gr, in: container)
        r.origin.x += origin.x
        r.origin.y += origin.y
        return r
    }
}

// MARK: - Text view that toggles a checkbox on click

final class MarkdownTextView: NSTextView {
    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        guard let lm = layoutManager, let tc = textContainer else {
            super.mouseDown(with: event); return
        }
        let inset = textContainerInset
        let pt = NSPoint(x: p.x - inset.width, y: p.y - inset.height)
        let gi = lm.glyphIndex(for: pt, in: tc)
        let ci = lm.characterIndexForGlyph(at: gi)
        let nsString = string as NSString
        guard ci < nsString.length else { super.mouseDown(with: event); return }

        // 该字符是否落在一个 checkbox marker 上？
        var isBox = false
        textStorage?.enumerateAttribute(.snCheckbox,
                                        in: NSRange(location: ci, length: 1)) { v, _, stop in
            if v != nil { isBox = true; stop.pointee = true }
        }
        guard isBox else { super.mouseDown(with: event); return }

        // 找到本行的 [ ] / [x]，翻转内部字符
        let lineRange = nsString.lineRange(for: NSRange(location: ci, length: 0))
        let line = nsString.substring(with: lineRange)
        guard let m = Self.taskBox.firstMatch(
            in: line, range: NSRange(location: 0, length: (line as NSString).length))
        else { super.mouseDown(with: event); return }

        let innerInLine = m.range(at: 1)                       // 方括号里那一个字符
        let loc = lineRange.location + innerInLine.location
        let cur = nsString.substring(with: NSRange(location: loc, length: 1))
        let next = (cur == " ") ? "x" : " "
        let target = NSRange(location: loc, length: 1)
        if shouldChangeText(in: target, replacementString: next) {
            textStorage?.replaceCharacters(in: target, with: next)
            didChangeText()
        }
    }

    static let taskBox = try! NSRegularExpression(pattern: "^\\s*[-*+] \\[([ xX])\\] ")
}

// MARK: - Live Markdown editor (Bear-style: no mode switch)

/// 单一始终可编辑的文本视图。输入即渲染：标记符（`#` `**` `` ` `` `>` `[]()`）
/// **保留但变淡**；list `-` → 真 • 圆点；`- [ ]`/`- [x]` → 真复选框（可点）。
/// 不切 view/edit。只改属性 + 自定义 layout manager 画图形，不改字符 →
/// 光标/选区/撤销天然不被打断。
struct LiveMarkdownEditor: NSViewRepresentable {

    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        let lm = MarkdownLayoutManager()
        let store = NSTextStorage()
        store.addLayoutManager(lm)
        let container = NSTextContainer(size: NSSize(width: 0,
                                                     height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        lm.addTextContainer(container)

        let tv = MarkdownTextView(frame: .zero, textContainer: container)
        tv.autoresizingMask = [.width]
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.textContainerInset = NSSize(width: 4, height: 8)

        tv.delegate = context.coordinator
        store.delegate = context.coordinator
        tv.isRichText = false
        tv.allowsUndo = true
        tv.font = EditorFont.body(15)
        tv.textColor = NSColor(Color.textPrimary)
        tv.insertionPointColor = NSColor(Color.sage)
        tv.drawsBackground = false
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.isAutomaticSpellingCorrectionEnabled = false
        tv.isContinuousSpellCheckingEnabled = false
        tv.string = text
        context.coordinator.highlight(tv.textStorage)

        scroll.documentView = tv
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

        private var bodyColor:  NSColor { NSColor(Color.textPrimary) }
        private var fadedColor: NSColor { NSColor(Color.textFaint) }
        private var mutedColor: NSColor { NSColor(Color.textMuted) }
        private var linkColor:  NSColor { NSColor(Color.sageDeep) }
        private var accentSoft: NSColor { NSColor(Color.sageSoft) }
        private let clear = NSColor.clear

        /// 全量重刷（笔记短，开销可忽略）。只改属性不改字符 → 选区/撤销不受影响。
        func highlight(_ storage: NSTextStorage?) {
            guard let storage else { return }
            let ns = storage.string as NSString
            let full = NSRange(location: 0, length: ns.length)
            guard full.length > 0 else { return }

            storage.beginEditing()
            storage.setAttributes([
                .font: EditorFont.body(15),
                .foregroundColor: bodyColor
            ], range: full)
            // 清掉上一轮的自定义标记，避免残留
            storage.removeAttribute(.snBullet, range: full)
            storage.removeAttribute(.snCheckbox, range: full)
            storage.removeAttribute(.strikethroughStyle, range: full)

            var inFence = false
            ns.enumerateSubstrings(in: full, options: .byLines) { line, lineRange, _, _ in
                guard let line else { return }
                let t = line.trimmingCharacters(in: .whitespaces)
                let lineNS = line as NSString
                let lineLen = lineNS.length

                if t.hasPrefix("```") {
                    inFence.toggle()
                    storage.addAttributes([.font: EditorFont.mono(13.5),
                                           .foregroundColor: self.fadedColor], range: lineRange)
                    return
                }
                if inFence {
                    storage.addAttributes([.font: EditorFont.mono(13.5)], range: lineRange)
                    return
                }
                // 标题
                if let m = Self.heading.firstMatch(in: line, range: NSRange(location: 0, length: lineLen)) {
                    let hashes = lineNS.substring(with: m.range(at: 1)).count
                    let size: CGFloat = hashes == 1 ? 28 : (hashes == 2 ? 21 : 17)
                    storage.addAttribute(.font, value: EditorFont.display(size), range: lineRange)
                    let mr = NSRange(location: lineRange.location,
                                     length: min(hashes + 1, lineRange.length))
                    storage.addAttribute(.foregroundColor, value: self.fadedColor, range: mr)
                    return
                }
                // To-Do：- [ ] / - [x]（group1 = "- " 前缀，group2 = 勾选字符）
                if let m = Self.task.firstMatch(in: line, range: NSRange(location: 0, length: lineLen)) {
                    let checked = lineNS.substring(with: m.range(at: 2)).lowercased() == "x"
                    let prefix = m.range(at: 0)                      // "- [ ] " 整段
                    let g1 = m.range(at: 1)                          // "\s*[-*+] "
                    let boxOpen = g1.location + g1.length            // '[' 的行内位置
                    // 整个前缀隐形（• 不画，复选框代替）
                    storage.addAttribute(.foregroundColor, value: self.clear,
                                          range: NSRange(location: lineRange.location,
                                                         length: min(prefix.length, lineRange.length)))
                    // 把 checkbox 画在 "[x]" 三个字符上
                    let boxRange = NSRange(location: lineRange.location + boxOpen, length: 3)
                    storage.addAttribute(.snCheckbox, value: checked, range: boxRange)
                    // 勾选后正文删除线 + 变淡
                    if checked {
                        let contentLoc = lineRange.location + prefix.length
                        let contentLen = lineRange.length - prefix.length
                        if contentLen > 0 {
                            let cr = NSRange(location: contentLoc, length: contentLen)
                            storage.addAttribute(.strikethroughStyle,
                                                  value: NSUnderlineStyle.single.rawValue, range: cr)
                            storage.addAttribute(.foregroundColor, value: self.mutedColor, range: cr)
                        }
                    }
                    return
                }
                // 普通 bullet：-/*/+
                if let m = Self.bullet.firstMatch(in: line, range: NSRange(location: 0, length: lineLen)) {
                    let marker = m.range(at: 1)                      // 单个 -/*/+
                    let mr = NSRange(location: lineRange.location + marker.location, length: 1)
                    storage.addAttribute(.foregroundColor, value: self.clear, range: mr)
                    storage.addAttribute(.snBullet, value: true, range: mr)
                    return
                }
                // 引用
                if t.hasPrefix(">") {
                    storage.addAttribute(.foregroundColor, value: self.mutedColor, range: lineRange)
                    if let gt = line.firstIndex(of: ">") {
                        let off = line.distance(from: line.startIndex, to: gt)
                        storage.addAttribute(.foregroundColor, value: self.fadedColor,
                                             range: NSRange(location: lineRange.location + off, length: 1))
                    }
                }
            }

            self.applyInline(Self.code,   storage, ns, full) { s, c, mk in
                s.addAttribute(.font, value: EditorFont.mono(13), range: c)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: mk.0)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: mk.1)
            }
            self.applyInline(Self.bold,   storage, ns, full) { s, c, mk in
                s.addAttribute(.font, value: EditorFont.semibold(15), range: c)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: mk.0)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: mk.1)
            }
            self.applyInline(Self.italic, storage, ns, full) { s, c, mk in
                s.addAttribute(.font, value: EditorFont.italic(15), range: c)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: mk.0)
                s.addAttribute(.foregroundColor, value: self.fadedColor, range: mk.1)
            }
            self.applyLink(storage, ns, full)

            storage.endEditing()
        }

        private func applyInline(_ re: NSRegularExpression, _ s: NSTextStorage,
                                 _ ns: NSString, _ full: NSRange,
                                 _ style: (NSTextStorage, NSRange, (NSRange, NSRange)) -> Void) {
            for m in re.matches(in: ns as String, range: full) {
                guard m.numberOfRanges >= 2 else { continue }
                let whole = m.range(at: 0)
                let content = m.range(at: 1)
                let open = NSRange(location: whole.location, length: content.location - whole.location)
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
                let preLen = label.location - whole.location
                s.addAttribute(.foregroundColor, value: fadedColor,
                               range: NSRange(location: whole.location, length: preLen))
                let tailLoc = label.location + label.length
                s.addAttribute(.foregroundColor, value: fadedColor,
                               range: NSRange(location: tailLoc,
                                              length: whole.location + whole.length - tailLoc))
            }
        }

        // 注意顺序：task 必须在 bullet 之前判定（`- [ ]` 也匹配 bullet）
        static let heading = try! NSRegularExpression(pattern: "^(#{1,6})\\s")
        static let task    = try! NSRegularExpression(pattern: "^(\\s*[-*+] )\\[([ xX])\\] ")
        static let bullet  = try! NSRegularExpression(pattern: "^\\s*([-*+]) ")
        static let code    = try! NSRegularExpression(pattern: "`([^`\\n]+)`")
        static let bold    = try! NSRegularExpression(pattern: "\\*\\*([^*\\n]+)\\*\\*")
        static let italic  = try! NSRegularExpression(pattern: "(?<![\\*_])[\\*_]([^\\*_\\n]+)[\\*_](?![\\*_])")
        static let link    = try! NSRegularExpression(pattern: "\\[([^\\]\\n]+)\\]\\(([^)\\n]+)\\)")
    }
}
