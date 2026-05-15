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

    let panelController = PanelController()

    private var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        panelController.bootstrap()
        NSLog("[side-note] M1 launched. ⌃⇧Space or click menu bar to slide.")
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
        win.title = "About side-note"
        win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 360, height: 240))
        win.center()
        win.isReleasedWhenClosed = false
        aboutWindow = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - About view

private struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("side-note")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundStyle(.textPrimary)

            Text("v0.1.0 · M1 slide-in spike")
                .font(.system(size: 13))
                .tracking(0.4)
                .foregroundStyle(.sage)
                .textCase(.uppercase)

            Text("A Mac sidebar Markdown notebook that slides in from screen edge.")
                .font(.system(size: 12))
                .foregroundStyle(.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("⌃⇧Space to toggle")
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
