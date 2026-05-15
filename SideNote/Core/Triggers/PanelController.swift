import AppKit
import SwiftUI

/// 协调侧边栏面板的所有触发逻辑 + 动画时序。
///
/// **M1 升级（实测发现"卡感"后重构）**：
/// 之前: NSPanel 用 NSAnimationContext 滑位置 + SwiftUI 内容做 parallax = 两个时钟、
///        系统每帧重算 vibrancy + 阴影 = 卡。
/// 现在: NSPanel 不动；面板内 SwiftUI 用单一 spring 把 surface 从 offset(+slideBuffer)
///        滑到 offset(0)。NSAnimationContext 全删；用 SwiftUI 原生 `withAnimation` +
///        completion handler（macOS 14+）协调 panel 的 orderOut。
@Observable
final class PanelController {

    // MARK: - Observed state

    /// 当 true 时，SwiftUI 把 surface offset 设为 0（贴在右边、完全可见）。
    /// 当 false 时，offset 设为 +slideBuffer，surface 移出 panel 视野。
    private(set) var isPresented = false

    // MARK: - Private state

    private var panel: SlidePanel?
    private var hotkey: HotkeyService?

    /// 简单防抖：避免动画进行中重复触发导致状态混乱。
    private var isAnimating = false

    // MARK: - Lifecycle

    init() {}

    func bootstrap() {
        hotkey = HotkeyService { [weak self] in
            self?.toggle()
        }
    }

    // MARK: - Public API

    func toggle() {
        guard !isAnimating else { return }
        if isPresented {
            close()
        } else {
            open()
        }
    }

    func open() {
        guard !isPresented, !isAnimating else { return }
        isAnimating = true

        // 1. 确保 panel 存在 + 摆到 target 位置（处理多显示器场景）
        let panel = ensurePanel()
        panel.snapToTarget()

        // 2. 允许点击（同时 left buffer 区域由 hitTest 自动穿透）
        panel.ignoresMouseEvents = false

        // 3. 上屏。此时 isPresented = false，surface 还在 offset(+slideBuffer) 位置 = 屏外，
        //    用户视觉上看不到任何内容（panel 区域全透明）。
        panel.orderFrontRegardless()

        // 4. 触发 SwiftUI 动画：isPresented false → true，surface 从屏外 spring 到 in-place
        withAnimation(.slideIn) {
            isPresented = true
        } completion: { [weak self] in
            self?.isAnimating = false
        }
    }

    func close() {
        guard isPresented, !isAnimating else { return }
        isAnimating = true

        // 1. 触发 SwiftUI 动画：isPresented true → false，surface 从 in-place easeIn 到屏外
        withAnimation(.slideOut) {
            isPresented = false
        } completion: { [weak self] in
            guard let self else { return }
            // 2. 动画结束后：panel orderOut（彻底从 Window list 移除）+ 关闭点击
            self.panel?.orderOut(nil)
            self.panel?.ignoresMouseEvents = true
            self.isAnimating = false
        }
    }

    // MARK: - Panel lifecycle

    private func ensurePanel() -> SlidePanel {
        if let panel = panel { return panel }
        let panel = SlidePanel()
        let host = SidebarPanelHost(controller: self)
        let hosting = ClickThroughHostingView(rootView: host)
        hosting.frame = NSRect(
            x: 0, y: 0,
            width: PanelGeometry.totalWidth,
            height: PanelGeometry.totalHeight
        )
        // 让 left buffer 区域（slideBuffer 宽）的点击穿透。右侧 visibleWidth (380) 才是
        // 真正交互的侧边栏。
        hosting.interactiveInsets = NSEdgeInsets(
            top: 0,
            left: PanelGeometry.slideBuffer,
            bottom: 0,
            right: 0
        )
        panel.contentView = hosting
        self.panel = panel
        return panel
    }
}
