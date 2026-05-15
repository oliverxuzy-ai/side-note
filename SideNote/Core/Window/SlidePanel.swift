import AppKit

/// 侧边栏 NSPanel。M1 升级后：**面板本身不动**，所有滑入/滑出动画由内部 SwiftUI 驱动。
///
/// **关键架构变更（M1 实测后）**：
/// - 旧实现：面板用 NSAnimationContext 滑动位置 + SwiftUI 内容做 parallax
///   → 两个动画系统不同步 + 系统每帧重算 vibrancy + 阴影 = 卡感
/// - 新实现：面板永远固定在 target 位置；NSPanel 加宽容纳"滑出位置"；
///   SwiftUI 内部 surface 通过 .offset() 驱动滑入滑出（一个 spring 时钟）
///
/// **几何**：
/// - 可见侧边栏: 380×720，紧贴屏幕右边（留 20pt edgeMargin）
/// - NSPanel: 800×720 = 可见宽 380 + 滑出缓冲区 420（surface 滑到右边 +420 = 滑出 panel 视野）
/// - Panel 右边对齐 screen.maxX - edgeMargin
/// - Surface 内部 SwiftUI 用 trailing alignment，正常状态 offset 0 = 贴在 panel 右边
///
/// **click-through**：
/// - 关闭时 `ignoresMouseEvents = true`，整个 panel 区域穿透到下面 App
/// - 打开时 `ignoresMouseEvents = false`，但 left buffer (420pt) 区域由
///   `ClickThroughHostingView.hitTest` 返回 nil 让其穿透
final class SlidePanel: NSPanel {

    // MARK: - Init

    init() {
        let frame = NSRect(
            x: 0, y: 0,
            width: PanelGeometry.totalWidth,
            height: PanelGeometry.totalHeight
        )
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    private func configure() {
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        // 系统阴影**关闭**——SwiftUI 在 surface 上自绘阴影（panel 不再代表视觉边界）
        self.hasShadow = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = false
        self.animationBehavior = .none  // 不要系统默认窗口动画
        // 初始关闭，clicks 穿透
        self.ignoresMouseEvents = true
    }

    // MARK: - Geometry

    /// Panel 在屏幕上的目标位置：右边贴住 (screen.maxX - edgeMargin)。
    var targetFrame: NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(
                origin: .zero,
                size: NSSize(width: PanelGeometry.totalWidth, height: PanelGeometry.totalHeight)
            )
        }
        let v = screen.visibleFrame
        let x = v.maxX - PanelGeometry.edgeMargin - PanelGeometry.totalWidth
        let y = v.midY - PanelGeometry.totalHeight / 2
        return NSRect(
            x: x, y: y,
            width: PanelGeometry.totalWidth,
            height: PanelGeometry.totalHeight
        )
    }

    /// 一次性把 panel 摆到 target 位置（不动画）。在 open() 触发时调用，
    /// 处理多显示器 / 旋转屏 / 用户挪到副屏后的场景。
    func snapToTarget() {
        setFrame(targetFrame, display: false)
    }

    // MARK: - Required overrides for borderless panel

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
