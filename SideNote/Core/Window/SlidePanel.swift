import AppKit

/// `NSPanel` subclass that renders the sliding sidebar.
///
/// - 关键 styleMask: `.borderless`（自定圆角材质）+ `.nonactivatingPanel`（**不偷焦点**，
///   你从 VSCode 触发滑入时 VSCode 不应该失活）+ `.fullSizeContentView`。
/// - `collectionBehavior`: 在全屏 App 上也能浮出来，并能跨 Space 移动。
/// - `hasShadow = true`: 用系统级矩形阴影。圆角与阴影的微弱不匹配，在 sage 浅底上几乎看不出来。
///   M3 polish 阶段如果太丑再换成自绘 shadow。
///
/// 滑入 / 滑出动画时序由 `PanelController` 协调；本类只负责**渲染**和**位置**。
final class SlidePanel: NSPanel {

    // MARK: - Init

    init() {
        let initialFrame = NSRect(
            x: 0, y: 0,
            width: PanelGeometry.width,
            height: PanelGeometry.height
        )
        super.init(
            contentRect: initialFrame,
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
        self.hasShadow = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = false
        self.animationBehavior = .none  // 自己控制动画，关闭系统默认窗口动画
    }

    // MARK: - Frame targets

    /// 终态位置（屏幕右边缘，垂直居中）。
    var targetFrame: NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(origin: .zero, size: NSSize(width: PanelGeometry.width, height: PanelGeometry.height))
        }
        let visible = screen.visibleFrame
        let x = visible.maxX - PanelGeometry.width - PanelGeometry.edgeMargin
        let y = visible.midY - PanelGeometry.height / 2
        return NSRect(x: x, y: y, width: PanelGeometry.width, height: PanelGeometry.height)
    }

    /// 屏幕外起始位置（紧贴右边缘外侧）。
    var offscreenFrame: NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(origin: .zero, size: NSSize(width: PanelGeometry.width, height: PanelGeometry.height))
        }
        let visible = screen.visibleFrame
        let x = visible.maxX  // 完全在屏幕外，留 0 露出
        let y = visible.midY - PanelGeometry.height / 2
        return NSRect(x: x, y: y, width: PanelGeometry.width, height: PanelGeometry.height)
    }

    // MARK: - Animation

    /// 用 NSAnimationContext 把 panel 位置滑过去。
    /// - Parameters:
    ///   - frame: 终态 frame
    ///   - duration: 时长（秒）
    ///   - timing: timing function（ease-out for in, ease-in for out）
    ///   - completion: 动画完成回调（主线程）
    func animatePosition(
        to frame: NSRect,
        duration: TimeInterval,
        timing: CAMediaTimingFunctionName,
        completion: (() -> Void)? = nil
    ) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: timing)
            self.animator().setFrame(frame, display: true)
        }, completionHandler: {
            completion?()
        })
    }

    // MARK: - Borderless panel needs explicit acceptance

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
