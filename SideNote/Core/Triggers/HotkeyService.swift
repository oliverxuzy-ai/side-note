import AppKit
import HotKey

/// 全局热键注册器。v1 默认 `⌃⇧Space`（用户可改放到 v1.1 Preferences）。
///
/// 用 `soffes/HotKey` 包装 Carbon 的 RegisterEventHotKey。它在 macOS 14 上仍工作良好，
/// 是 menubar / 全局工具类应用的标准选择。
///
/// 注意：全局热键**不需要** Accessibility 权限——和 CGEventTap 不同。
final class HotkeyService {

    private var hotKey: HotKey?
    private let onTrigger: () -> Void

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        register()
    }

    deinit {
        hotKey = nil
    }

    private func register() {
        // ⌃⇧Space — Control + Shift + Space
        let hk = HotKey(key: .space, modifiers: [.control, .shift])
        hk.keyDownHandler = { [weak self] in
            self?.onTrigger()
        }
        self.hotKey = hk
    }
}
