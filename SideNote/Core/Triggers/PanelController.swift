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

    /// 笔记真相来源。由 AppDelegate 注入，传给 SidebarPanelHost。
    let store: NoteStore

    /// 简单防抖：避免动画进行中重复触发导致状态混乱。
    private var isAnimating = false

    // MARK: - Lifecycle

    init(store: NoteStore) {
        self.store = store
    }

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
        //    makeKey：nonactivating panel 取得键盘焦点（输入笔记 + ⌘ 快捷键必需），
        //    但不抢应用激活态。
        panel.makeKeyAndOrderFront(nil)

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
        let host = SidebarPanelHost(controller: self, store: store)
        let hosting = ClickThroughHostingView(rootView: host)
        hosting.frame = NSRect(
            x: 0, y: 0,
            width: PanelGeometry.totalWidth,
            height: PanelGeometry.totalHeight
        )
        // 让 4 个非交互区域的点击穿透：
        //   - 左 slideBuffer = 滑入缓冲区
        //   - 顶/底/右 shadowMargin = 阴影渲染区
        // 真正可交互区 = 中间偏右的 visibleWidth × visibleHeight 矩形（panel 几何里
        // 唯一渲染 surface 的那块）。
        hosting.interactiveInsets = NSEdgeInsets(
            top: PanelGeometry.shadowMargin,
            left: PanelGeometry.slideBuffer,
            bottom: PanelGeometry.shadowMargin,
            right: PanelGeometry.shadowMargin
        )
        panel.contentView = hosting
        self.panel = panel
        return panel
    }
}
