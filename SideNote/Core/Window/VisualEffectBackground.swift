import SwiftUI
import AppKit

/// SwiftUI wrapper for `NSVisualEffectView` — macOS native vibrancy material.
///
/// DESIGN.md spec:
/// - material: `.contentBackground` (在 light 模式下偏暖白)
/// - blendingMode: `.behindWindow` (透过窗口背后的桌面壁纸)
/// - state: `.active` (强制保持活跃，即使应用失焦也不变暗)
///
/// 上面会叠一层 `Color.canvas.opacity(0.92)` 让 sage tint 透过来 ~8%。
struct VisualEffectBackground: NSViewRepresentable {

    var material: NSVisualEffectView.Material = .contentBackground
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = true
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}
