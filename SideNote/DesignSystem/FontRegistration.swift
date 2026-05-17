import CoreText
import Foundation

/// 把打包进 .app 的字体文件在进程内注册，让 `Font.custom(psName:)` 能找到。
///
/// 为什么用运行时 `CTFontManagerRegisterFontsForURL` 而不是 Info.plist 的
/// `ATSApplicationFontsPath`：xcodegen 把资源平铺进 `Contents/Resources/`，
/// 子目录结构不保证保留，`ATSApplicationFontsPath` 指向的相对路径会落空。
/// 运行时扫 bundle 递归找字体文件再注册 = 不依赖打包布局，确定。
///
/// 进程作用域（`.process`）：只对本 App 可见，不污染系统字体表。
enum FontRegistration {

    /// App 启动最早期调用（任何 SwiftUI 视图构建之前）。
    static func registerBundledFonts() {
        let exts: Set<String> = ["otf", "ttf"]
        guard let resourceURL = Bundle.main.resourceURL else { return }

        // 递归：不管 xcodegen 把字体平铺到 Resources/ 还是保留 Fonts/ 子目录都能找到
        var urls: [URL] = []
        if let e = FileManager.default.enumerator(
            at: resourceURL, includingPropertiesForKeys: nil
        ) {
            for case let url as URL in e where exts.contains(url.pathExtension.lowercased()) {
                urls.append(url)
            }
        }

        for url in urls {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // 已注册 / 重复不是致命错误——只在真失败时记一笔
                NSLog("[HoverNote] font register skipped: \(url.lastPathComponent)")
            }
        }
    }
}
