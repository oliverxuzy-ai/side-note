import SwiftUI
import AppKit

/// 纯文本 Markdown 编辑器（NSTextView 包装）。
///
/// M2 = 干净的可编辑文本区，glass 背景透出来。
/// 语法高亮（H1 加粗、code 等宽）和 live preview 是 M3 polish，这里先不做——
/// DoD 是「能用、能写、自动存」，不是好看。
struct MarkdownEditor: NSViewRepresentable {

    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        guard let tv = scroll.documentView as? NSTextView else { return scroll }

        tv.delegate = context.coordinator
        tv.string = text
        tv.isRichText = false
        tv.allowsUndo = true
        tv.font = NSFont.systemFont(ofSize: 15)
        tv.textColor = NSColor(Color.textPrimary)
        tv.insertionPointColor = NSColor(Color.sage)
        tv.drawsBackground = false
        tv.textContainerInset = NSSize(width: 4, height: 8)
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.isContinuousSpellCheckingEnabled = false

        scroll.drawsBackground = false
        scroll.backgroundColor = .clear
        scroll.hasVerticalScroller = true
        scroll.scrollerStyle = .overlay
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let tv = scroll.documentView as? NSTextView else { return }
        // 只在外部（非本编辑器键入）改了 text 时才覆盖，避免打断光标 / 输入法
        if tv.string != text && !context.coordinator.isEditing {
            tv.string = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: MarkdownEditor
        var isEditing = false

        init(_ parent: MarkdownEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            isEditing = true
            parent.text = tv.string
            DispatchQueue.main.async { self.isEditing = false }
        }
    }
}
