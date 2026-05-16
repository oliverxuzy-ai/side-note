import SwiftUI
import AppKit
import HotKey

/// 录制快捷键的控件：点一下进入录制态，按下"≥1 个 ⌘/⌃/⌥ + 一个普通键"即捕获。
/// Esc 取消，⌫ 恢复默认。纯 AppKit（NSView 直接收 keyDown）+ SwiftUI 桥，零额外依赖。
///
/// 视觉按 DESIGN.md：hairline 边框卡片、sage 聚焦环、JetBrains Mono 显示组合。
struct HotkeyRecorderField: NSViewRepresentable {

    /// 捕获到新组合（已校验合法）时回调。宿主负责持久化 + 刷新显示。
    let onCapture: (KeyCombo) -> Void
    /// 当前要显示的组合字符串（如 "⌃⇧Space"）。
    let display: String

    func makeNSView(context: Context) -> RecorderNSView {
        let v = RecorderNSView()
        v.onCapture = onCapture
        v.display = display
        return v
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        nsView.onCapture = onCapture
        if !nsView.isRecording { nsView.display = display }
    }

    final class RecorderNSView: NSView {

        var onCapture: ((KeyCombo) -> Void)?
        var display: String = "" { didSet { needsDisplay = true } }
        private(set) var isRecording = false { didSet { needsDisplay = true } }

        override var acceptsFirstResponder: Bool { true }
        override var intrinsicContentSize: NSSize { NSSize(width: NSView.noIntrinsicMetric, height: 30) }

        private var hovering = false { didSet { needsDisplay = true } }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach(removeTrackingArea)
            addTrackingArea(NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                owner: self))
        }

        override func mouseEntered(with event: NSEvent) { hovering = true }
        override func mouseExited(with event: NSEvent)  { hovering = false }

        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(self)
            isRecording = true
        }

        override func resignFirstResponder() -> Bool {
            isRecording = false
            return super.resignFirstResponder()
        }

        override func keyDown(with event: NSEvent) {
            guard isRecording else { super.keyDown(with: event); return }

            // Esc 取消
            if event.keyCode == 53 {
                isRecording = false
                window?.makeFirstResponder(nil)
                return
            }
            // ⌫ / Delete 恢复默认
            if event.keyCode == 51 || event.keyCode == 117 {
                RevealHotkey.reset()
                onCapture?(RevealHotkey.default)
                isRecording = false
                window?.makeFirstResponder(nil)
                return
            }

            // 必须含至少一个 ⌘/⌃/⌥（仅 Shift 不足以做安全的全局热键）
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard flags.contains(.command)
                    || flags.contains(.control)
                    || flags.contains(.option) else {
                NSSound.beep()
                return
            }

            let combo = KeyCombo(carbonKeyCode: UInt32(event.keyCode),
                                 carbonModifiers: flags.carbonFlags)
            // 不认识的键（无 Key 映射）拒绝，避免存进去注册不上
            guard combo.key != nil else { NSSound.beep(); return }

            display = combo.description
            onCapture?(combo)
            isRecording = false
            window?.makeFirstResponder(nil)
        }

        override func draw(_ dirtyRect: NSRect) {
            let r = bounds.insetBy(dx: 1, dy: 1)
            let path = NSBezierPath(roundedRect: r, xRadius: 8, yRadius: 8)

            NSColor.white.withAlphaComponent(hovering && !isRecording ? 0.72 : 0.55).setFill()
            path.fill()

            if isRecording {
                NSColor(Color.sage).setStroke()
                path.lineWidth = 2
            } else if hovering {
                NSColor(Color.textPrimary).withAlphaComponent(0.18).setStroke()
                path.lineWidth = 1
            } else {
                NSColor(Color.textPrimary).withAlphaComponent(0.07).setStroke()
                path.lineWidth = 1
            }
            path.stroke()

            let text = isRecording ? "Press shortcut…" : (display.isEmpty ? "—" : display)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont(name: "JetBrainsMono-Regular", size: 13)
                    ?? .monospacedSystemFont(ofSize: 13, weight: .regular),
                .foregroundColor: isRecording
                    ? NSColor(Color.sageDeep)
                    : NSColor(Color.textPrimary)
            ]
            let size = (text as NSString).size(withAttributes: attrs)
            let p = NSPoint(x: r.midX - size.width / 2, y: r.midY - size.height / 2)
            (text as NSString).draw(at: p, withAttributes: attrs)
        }
    }
}
