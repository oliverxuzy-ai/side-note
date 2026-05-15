import SwiftUI
import AppKit

/// SwiftUI wrapper for `NSVisualEffectView` — macOS native vibrancy material.
///
/// DESIGN.md M1 升级后 spec:
/// - material: `.sidebar` (Finder / Apple Notes / Things 3 侧栏所用，最显玻璃感)
/// - blendingMode: `.behindWindow` (透到桌面壁纸)
/// - state: `.active` (失焦也不变暗，保持视觉一致性)
///
/// 上层会叠 sage tint (12%) + warm white wash (45%)，总不透明度 ~52%，
/// 让 ~50% 桌面壁纸透过来，达到"真玻璃"体感。
struct VisualEffectBackground: NSViewRepresentable {

    var material: NSVisualEffectView.Material = .sidebar
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
