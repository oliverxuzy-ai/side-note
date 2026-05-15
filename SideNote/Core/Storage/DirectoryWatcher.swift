import Foundation

/// 监听一个目录里 `.md` 文件的变化（增 / 删 / 改 / 改名）。
///
/// 用 **FSEventStream** 而不是 PLAN.md 最初写的 `DispatchSource` vnode 监听：
/// vnode 只在目录条目增删时触发，**不报文件内容修改** —— 而 M2 的核心需求之一
/// 是"当前编辑的笔记被外部编辑器改了要提示"，那必须感知内容修改。
/// `kFSEventStreamCreateFlagFileEvents` 给逐文件、含内容修改的事件。
///
/// 事件做了 0.3s 合并（latency 参数）+ 主线程回调，避免一次保存触发多次扫描。
final class DirectoryWatcher {

    private let url: URL
    private let onChange: () -> Void
    private var stream: FSEventStreamRef?
    private let queue = DispatchQueue(label: "com.oliverxuzy.side-note.fswatch")

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
    }

    deinit { stop() }

    func start() {
        guard stream == nil else { return }

        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<DirectoryWatcher>.fromOpaque(info).takeUnretainedValue()
            DispatchQueue.main.async { watcher.onChange() }
        }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            [url.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.3,
            FSEventStreamCreateFlags(
                kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer
            )
        ) else { return }

        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
        self.stream = stream
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }
}
