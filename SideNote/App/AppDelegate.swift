import AppKit
import SwiftUI

/// 应用启动 + 全局协调。
///
/// M1 改动：
/// - 从 M0 的"直接管 NSPanel"重构为通过 `PanelController` 协调
/// - 添加全局热键 ⌃⇧Space
/// - About 窗口保留
///
/// 触发链：
/// - 菜单栏 icon 点击 → `SideNoteApp` 调用 `toggleSidebar()` → `PanelController.toggle()`
/// - ⌃⇧Space     → `HotkeyService` 直接调用 `PanelController.toggle()`
final class AppDelegate: NSObject, NSApplicationDelegate {

    let noteStore = NoteStore()
    lazy var panelController = PanelController(store: noteStore)
    lazy var edgeHover = EdgeHoverService(
        isPresented: { [weak self] in self?.panelController.isPresented ?? false },
        onTrigger:   { [weak self] in self?.panelController.open() }
    )

    private var aboutWindow: NSWindow?
    private var preferencesWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        FontRegistration.registerBundledFonts()  // 必须在任何 SwiftUI 视图构建前
        noteStore.bootstrap()
        panelController.bootstrap()
        applyEdgeHoverSetting()
        NSLog("[HoverNote] M3 launched. ⌃⇧Space / menu bar / edge-hover (opt-in).")
    }

    // MARK: - Edge hover

    /// 按 UserDefaults 开关 + AX 信任态决定 tap 起停。Preferences 改动后也调它。
    func applyEdgeHoverSetting() {
        let enabled = UserDefaults.standard.bool(forKey: "edgeHoverEnabled")
        if enabled && EdgeHoverService.hasAccessibility {
            edgeHover.start()
        } else {
            edgeHover.stop()
        }
    }

    // MARK: - Sidebar

    func toggleSidebar() {
        panelController.toggle()
    }

    // MARK: - About

    func openAbout() {
        if let win = aboutWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let hosting = NSHostingController(rootView: AboutView())
        let win = NSWindow(contentViewController: hosting)
        win.title = "About HoverNote"
        win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 360, height: 240))
        win.center()
        win.isReleasedWhenClosed = false
        aboutWindow = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Preferences

    func openPreferences() {
        if let win = preferencesWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = PreferencesView(
            onToggle: { [weak self] _ in self?.applyEdgeHoverSetting() },
            isAXTrusted: { EdgeHoverService.hasAccessibility },
            requestAX: { EdgeHoverService.requestAccessibility() }
        )
        let hosting = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: hosting)
        win.title = "HoverNote Preferences"
        win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 380, height: 380))
        win.center()
        win.isReleasedWhenClosed = false
        preferencesWindow = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - About view

private struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("HoverNote")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundStyle(.textPrimary)

            Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")")
                .font(.system(size: 13))
                .tracking(0.4)
                .foregroundStyle(.sage)
                .textCase(.uppercase)

            Text("A Mac sidebar Markdown notebook that slides in from screen edge.")
                .font(.system(size: 12))
                .foregroundStyle(.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("Global shortcut · menu bar · screen edge")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.textFaint)
                .padding(.top, 6)

            Spacer()
        }
        .padding(.top, 28)
        .frame(width: 360, height: 240)
        .background(Color.canvas)
    }
}
