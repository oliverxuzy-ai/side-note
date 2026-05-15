import AppKit
import SwiftUI

/// 协调侧边栏面板的所有触发逻辑 + 动画时序。
///
/// 这是 M1 的核心 orchestrator。它管：
/// 1. NSPanel 的位置动画（NSAnimationContext 320ms ease-out / 220ms ease-in）
/// 2. SwiftUI 内部内容的 parallax + alpha 动画时序（通过 `isContentPresented` 触发）
/// 3. 全局热键 ⌃⇧Space 触发
/// 4. 菜单栏点击触发
///
/// 两层动画的协同（slide-in）：
/// ```
/// t=0ms     panel 位置: offscreen → target (NSAnimationContext, 320ms ease-out)
/// t=0ms     content.isPresented = false (offset(+12, alpha=0))
/// t=80ms    content.isPresented = true  → SwiftUI spring 触发
///           (content 自己 spring 到 offset 0, alpha 1)
/// t=380ms   全部稳定
/// ```
///
/// 两层动画的协同（slide-out）：
/// ```
/// t=0ms     content.isPresented = false → SwiftUI easeIn 100ms fade
/// t=100ms   panel 位置: target → offscreen (NSAnimationContext, 220ms ease-in)
/// t=320ms   orderOut(nil)
/// ```
@Observable
final class PanelController {

    // MARK: - Observed state

    /// SwiftUI 用这个 flag 决定内容 layer 的可见性 + parallax。
    /// 注意：和 `isPanelVisible` 区分——panel 还在屏上时，content 可能已经在淡出。
    private(set) var isContentPresented = false

    // MARK: - Private state

    private var panel: SlidePanel?
    private var hotkey: HotkeyService?

    /// 标记动画正在进行，避免快速连续触发导致状态混乱。
    private var isAnimating = false

    // MARK: - Setup

    init() {}

    /// 在 AppDelegate.applicationDidFinishLaunching 里调用。
    func bootstrap() {
        // 1. 创建 panel（lazy 创建，避免启动时立即分配窗口资源）
        // 实际上 panel 在第一次 toggle() 时才创建——更省资源，且能正确读取
        // 当时的 NSScreen.main（多显示器场景）

        // 2. 注册热键
        hotkey = HotkeyService { [weak self] in
            self?.toggle()
        }
    }

    // MARK: - Public toggle API

    func toggle() {
        guard !isAnimating else { return }
        if isContentPresented {
            close()
        } else {
            open()
        }
    }

    func open() {
        guard !isContentPresented, !isAnimating else { return }
        isAnimating = true

        // Lazy 创建 panel（第一次触发时）
        let panel = ensurePanel()

        // 1. 把 panel 移到屏幕外起始位置，然后显示
        panel.setFrame(panel.offscreenFrame, display: false)
        panel.orderFrontRegardless()

        // 2. 启动 panel 位置滑入（NSAnimationContext, 320ms ease-out）
        panel.animatePosition(
            to: panel.targetFrame,
            duration: 0.32,
            timing: .easeOut,
            completion: { [weak self] in
                self?.isAnimating = false
            }
        )

        // 3. 80ms 后触发 content layer 动画（SwiftUI spring）
        DispatchQueue.main.asyncAfter(deadline: .now() + PanelGeometry.contentDelay) { [weak self] in
            self?.isContentPresented = true
        }
    }

    func close() {
        guard isContentPresented, !isAnimating else { return }
        isAnimating = true

        // 1. content 先开始淡出（SwiftUI 自动 100ms easeIn）
        isContentPresented = false

        // 2. 100ms 后启动 panel 滑出
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
            guard let self, let panel = self.panel else { return }
            panel.animatePosition(
                to: panel.offscreenFrame,
                duration: 0.22,
                timing: .easeIn,
                completion: { [weak self] in
                    panel.orderOut(nil)
                    self?.isAnimating = false
                }
            )
        }
    }

    // MARK: - Panel lifecycle

    private func ensurePanel() -> SlidePanel {
        if let panel = panel { return panel }
        let panel = SlidePanel()
        let view = SidebarPanelView(controller: self)
        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = NSRect(
            x: 0, y: 0,
            width: PanelGeometry.width,
            height: PanelGeometry.height
        )
        panel.contentViewController = hosting
        self.panel = panel
        return panel
    }
}
