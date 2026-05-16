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
    /// 标在围栏代码块整段（含 ``` 行）上 → layout manager 画圆角底 + hairline 边。
    static let snCodeBlock = NSAttributedString.Key("snCodeBlock")
    /// 标在引用块整段上 → layout manager 画左侧 2pt accent-soft 立柱。
    static let snQuote = NSAttributedString.Key("snQuote")
}

// MARK: - Layout manager that draws bullets / checkboxes

/// 原始标记字符在 highlighter 里被设成 `.clear`（隐形但仍占位、文本不变），
/// 这里在它们的位置上画真正的 • / ☐ / ☑。光标/撤销/选区完全不受影响。
final class MarkdownLayoutManager: NSLayoutManager {

    /// 背景层：代码块圆角底 + hairline 边、引用块左立柱、行内 code wash。
    /// 在 glyph 之前画（drawGlyphs 之后画 • / ☐ / ☑ 前景）。
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin) // 行内 code .backgroundColor
        guard let ts = textStorage, textContainers.first != nil else { return }
        let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        // 围栏代码块：取整段所有 line fragment 的并集 → 一个圆角块
        ts.enumerateAttribute(.snCodeBlock, in: charRange) { value, range, _ in
            guard value != nil else { return }
            let gr = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            var union = NSRect.null
            self.enumerateLineFragments(forGlyphRange: gr) { rect, _, _, _, _ in
                union = union.isNull ? rect : union.union(rect)
            }
            guard !union.isNull else { return }
            let bg = NSRect(x: origin.x + union.minX + 2,
                            y: origin.y + union.minY + 1,
                            width: union.width - 4,
                            height: union.height - 2)
            let path = NSBezierPath(roundedRect: bg, xRadius: 8, yRadius: 8)
            NSColor(Color.textPrimary).withAlphaComponent(0.04).setFill()
            path.fill()
            NSColor(Color.textPrimary).withAlphaComponent(0.07).setStroke()
            path.lineWidth = 1
            path.stroke()
        }

        // 引用块：每个 line fragment 左侧 2pt accent-soft 立柱
        ts.enumerateAttribute(.snQuote, in: charRange) { value, range, _ in
            guard value != nil else { return }
            let gr = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            self.enumerateLineFragments(forGlyphRange: gr) { rect, _, _, _, _ in
                let bar = NSRect(x: origin.x + rect.minX + 3,
                                 y: origin.y + rect.minY + 1,
                                 width: 2,
                                 height: rect.height - 2)
                NSColor(Color.sageSoft).setFill()
                NSBezierPath(rect: bar).fill()
            }
        }
    }

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
        let slash = SlashMenuController()
        var isEditing = false

        init(_ parent: LiveMarkdownEditor) { self.parent = parent }

        func textDidChange(_ note: Notification) {
            guard let tv = note.object as? NSTextView else { return }
            isEditing = true
            parent.text = tv.string
            slash.handleTextChange(tv)
            DispatchQueue.main.async { self.isEditing = false }
        }

        func textViewDidChangeSelection(_ note: Notification) {
            guard slash.isVisible, let tv = note.object as? NSTextView else { return }
            slash.handleTextChange(tv)   // caret 移出 "/token" → 自动关
        }

        /// slash 菜单可见时拦截方向键/回车/Tab/Esc 驱动选择，文本视图仍是第一响应者。
        func textView(_ tv: NSTextView, doCommandBy sel: Selector) -> Bool {
            guard slash.isVisible else { return false }
            switch sel {
            case #selector(NSResponder.moveDown(_:)):      slash.move(1);  return true
            case #selector(NSResponder.moveUp(_:)):        slash.move(-1); return true
            case #selector(NSResponder.insertNewline(_:)),
                 #selector(NSResponder.insertTab(_:)):     slash.confirm(); return true
            case #selector(NSResponder.cancelOperation(_:)): slash.dismiss(); return true
            default: return false
            }
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
            // setAttributes 整体替换属性字典 → 自动清掉上一轮的 paragraphStyle /
            // backgroundColor / snBullet / snCheckbox / snCodeBlock / snQuote 残留。
            storage.setAttributes([
                .font: EditorFont.body(15),
                .foregroundColor: bodyColor
            ], range: full)

            var inFence = false
            ns.enumerateSubstrings(in: full, options: .byLines) { line, lineRange, encl, _ in
                guard let line else { return }
                let t = line.trimmingCharacters(in: .whitespaces)
                let lineNS = line as NSString
                let lineLen = lineNS.length

                // 围栏代码块（``` 行 + 块内行都标 snCodeBlock，整段连续 → 一个圆角块）
                if t.hasPrefix("```") {
                    inFence.toggle()
                    storage.addAttributes([.font: EditorFont.mono(13.5),
                                           .foregroundColor: self.fadedColor,
                                           .snCodeBlock: true,
                                           .paragraphStyle: Self.codeStyle], range: encl)
                    return
                }
                if inFence {
                    storage.addAttributes([.font: EditorFont.mono(13.5),
                                           .snCodeBlock: true,
                                           .paragraphStyle: Self.codeStyle], range: encl)
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
                // To-Do：- [ ] / - [x]（group0 = 整前缀，group1 = "\s*[-*+] "，group2 = 勾选字符）
                if let m = Self.task.firstMatch(in: line, range: NSRange(location: 0, length: lineLen)) {
                    let checked = lineNS.substring(with: m.range(at: 2)).lowercased() == "x"
                    let prefix = m.range(at: 0)                      // "- [ ] " 整段
                    let g1 = m.range(at: 1)                          // "\s*[-*+] "
                    let boxOpen = g1.location + g1.length            // '[' 的行内位置
                    let leadWS = lineNS.substring(with: m.range(at: 1))
                        .prefix { $0 == " " || $0 == "\t" }
                    self.hang(storage, encl,
                              first: self.w(String(leadWS)),
                              body: self.w(lineNS.substring(with: prefix)))
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
                    let g0 = m.range(at: 0)                          // 含前导空白 + "-" + 空格
                    let marker = m.range(at: 1)                      // 单个 -/*/+
                    let leadWS = lineNS.substring(with: g0).prefix { $0 == " " || $0 == "\t" }
                    self.hang(storage, encl,
                              first: self.w(String(leadWS)),
                              body: self.w(lineNS.substring(with: g0)))
                    let mr = NSRange(location: lineRange.location + marker.location, length: 1)
                    storage.addAttribute(.foregroundColor, value: self.clear, range: mr)
                    storage.addAttribute(.snBullet, value: true, range: mr)
                    return
                }
                // 有序列表：1. 2. …（数字保留可见——它是语义不是语法；只挂悬挂缩进）
                if let m = Self.ordered.firstMatch(in: line, range: NSRange(location: 0, length: lineLen)) {
                    let g0 = m.range(at: 0)                          // "  12. "
                    let leadWS = lineNS.substring(with: m.range(at: 1))
                    self.hang(storage, encl,
                              first: self.w(leadWS),
                              body: self.w(lineNS.substring(with: g0)))
                    return
                }
                // 引用：左立柱由 layout manager 画；这里挂 12pt 缩进 + 变淡文字
                if t.hasPrefix(">") {
                    storage.addAttribute(.snQuote, value: true, range: encl)
                    storage.addAttribute(.paragraphStyle, value: Self.quoteStyle, range: encl)
                    storage.addAttribute(.foregroundColor, value: self.mutedColor, range: lineRange)
                    if let gt = line.firstIndex(of: ">") {
                        let off = line.distance(from: line.startIndex, to: gt)
                        storage.addAttribute(.foregroundColor, value: self.fadedColor,
                                             range: NSRange(location: lineRange.location + off, length: 1))
                    }
                }
            }

            // 行内 pass 跳过代码块内部（围栏里的 `` ` `` / ** 不再二次上样式）
            self.applyInline(Self.code,   storage, ns, full) { s, c, mk in
                s.addAttribute(.font, value: EditorFont.mono(13), range: c)
                s.addAttribute(.backgroundColor,
                               value: NSColor(Color.textPrimary).withAlphaComponent(0.05), range: c)
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

        /// 列表悬挂缩进：第一行从 marker 处起，换行回绕对齐到内容（非 marker）。
        /// proportional 字体下这是 live-edit「做得好不好」的第一杠杆。
        private func hang(_ s: NSTextStorage, _ range: NSRange,
                          first: CGFloat, body: CGFloat) {
            let p = NSMutableParagraphStyle()
            p.firstLineHeadIndent = first
            p.headIndent = body
            s.addAttribute(.paragraphStyle, value: p, range: range)
        }

        /// 用 body 字体测一段字符串的渲染宽度（算悬挂缩进的列宽）。
        private func w(_ str: String) -> CGFloat {
            (str as NSString).size(withAttributes: [.font: EditorFont.body(15)]).width
        }

        private func applyInline(_ re: NSRegularExpression, _ s: NSTextStorage,
                                 _ ns: NSString, _ full: NSRange,
                                 _ style: (NSTextStorage, NSRange, (NSRange, NSRange)) -> Void) {
            for m in re.matches(in: ns as String, range: full) {
                guard m.numberOfRanges >= 2 else { continue }
                let whole = m.range(at: 0)
                if s.attribute(.snCodeBlock, at: whole.location, effectiveRange: nil) != nil { continue }
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
                if s.attribute(.snCodeBlock, at: whole.location, effectiveRange: nil) != nil { continue }
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
        static let ordered = try! NSRegularExpression(pattern: "^(\\s*)\\d{1,9}\\. ")
        static let code    = try! NSRegularExpression(pattern: "`([^`\\n]+)`")
        static let bold    = try! NSRegularExpression(pattern: "\\*\\*([^*\\n]+)\\*\\*")
        static let italic  = try! NSRegularExpression(pattern: "(?<![\\*_])[\\*_]([^\\*_\\n]+)[\\*_](?![\\*_])")
        static let link    = try! NSRegularExpression(pattern: "\\[([^\\]\\n]+)\\]\\(([^)\\n]+)\\)")

        /// 代码块段落样式：10pt 左缩进 + 右内缩，给圆角底留 padding（DESIGN.md）。
        static let codeStyle: NSParagraphStyle = {
            let p = NSMutableParagraphStyle()
            p.firstLineHeadIndent = 10
            p.headIndent = 10
            p.tailIndent = -8
            return p
        }()

        /// 引用块段落样式：12pt 缩进，给左立柱让位（DESIGN.md）。
        static let quoteStyle: NSParagraphStyle = {
            let p = NSMutableParagraphStyle()
            p.firstLineHeadIndent = 12
            p.headIndent = 12
            return p
        }()
    }
}
