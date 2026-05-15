import AppKit
import SwiftUI

/// NSHostingView 子类，定制 `hitTest` 让"可见区域以外"的点击穿透到下面的 App。
///
/// 背景：M1 架构里 NSPanel 比可见的侧边栏宽 ~420pt（用来容纳"滑出"位置）。
/// 那 420pt buffer 区域是 SwiftUI Color.clear，**视觉上**透明，但 NSPanel 默认
/// 会捕获 panel 范围内所有的点击 —— 包括 buffer 区域。结果：用户点击侧边栏
/// 左边 420pt 的屏幕区域时，点击被 NSPanel"吞掉"，不会传给下面的 App。糟糕的 UX。
///
/// 这个子类通过覆盖 `hitTest(_:)`，当点击落在"可见侧边栏"区域之外时返回 `nil`，
/// NSPanel 据此把点击放走传给下面的 App。
///
/// `interactiveInsets` 描述"可见区域"相对 hosting view bounds 的 inset：
/// 通常 `NSEdgeInsets(top: 0, left: slideBuffer, bottom: 0, right: 0)` —— 即可见
/// 区域是右侧 380pt。
final class ClickThroughHostingView<Content: View>: NSHostingView<Content> {

    /// 可点击区域相对 view bounds 的 inset。默认全 0（全部可点击 = 普通 NSHostingView 行为）。
    var interactiveInsets: NSEdgeInsets = NSEdgeInsets()

    override func hitTest(_ point: NSPoint) -> NSView? {
        let interactive = NSRect(
            x: bounds.minX + interactiveInsets.left,
            y: bounds.minY + interactiveInsets.bottom,
            width: max(0, bounds.width  - interactiveInsets.left   - interactiveInsets.right),
            height: max(0, bounds.height - interactiveInsets.top - interactiveInsets.bottom)
        )
        if interactive.contains(point) {
            return super.hitTest(point)
        }
        return nil  // panel will fall through to underlying window
    }
}
