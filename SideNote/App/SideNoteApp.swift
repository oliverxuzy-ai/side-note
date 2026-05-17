import SwiftUI

/// HoverNote · entry point.
///
/// 这是一个 LSUIElement = true 的菜单栏 App。
/// - 不通过 SwiftUI Scene 管理主面板（NSPanel 由 AppDelegate 手动管理，避免 SwiftUI Window 的限制）。
/// - MenuBarExtra 只负责状态栏图标和右键菜单。
/// - 主面板（滑入侧边栏）由 AppDelegate.toggleSidebar() 控制。
@main
struct SideNoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("HoverNote", systemImage: "note.text") {
            Button("Toggle sidebar") {
                appDelegate.toggleSidebar()
            }
            .keyboardShortcut("s", modifiers: [.command])

            Divider()

            Button("Preferences…") {
                appDelegate.openPreferences()
            }
            .keyboardShortcut(",", modifiers: [.command])

            Button("About HoverNote") {
                appDelegate.openAbout()
            }

            Divider()

            Button("Quit HoverNote") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .menuBarExtraStyle(.menu)
    }
}
