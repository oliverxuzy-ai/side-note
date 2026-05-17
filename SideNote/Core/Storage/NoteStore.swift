import Foundation
import Observation

/// 全部笔记的真相来源。磁盘 = `~/Documents/SideNote/*.md`，内存 = `notes`（已排序）。
///
/// 设计原则：**磁盘是权威**。内存只是磁盘的一个视图 + 编辑缓冲。
/// 写走原子写入（`Data.write(.atomic)` 内部就是 temp + rename，不必手搓）。
/// FSEvents 回来后用「我们最后写下的原文」过滤掉自己触发的事件，
/// 剩下的才是真·外部修改 → 给当前打开的那条笔记打 externally-modified 标记。
@Observable
final class NoteStore {

    // MARK: - Observed

    private(set) var notes: [NoteFile] = []

    /// 被外部编辑器改过、且和我们内存版本不一致的笔记 id。
    /// DetailView 只在「这条正被打开编辑」时才把它显示成冲突条。
    private(set) var externallyModifiedIDs: Set<ULID> = []

    /// 当前在 DetailView 里打开的笔记（决定冲突条只在相关笔记上出现）。
    var editingID: ULID?

    // MARK: - Private

    let directoryURL: URL
    private var watcher: DirectoryWatcher?
    private var lastWritten: [ULID: String] = [:]
    private var saveTimers: [ULID: Timer] = [:]

    private static let ext = "md"

    // MARK: - Lifecycle

    init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL ?? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SideNote", isDirectory: true)
    }

    func bootstrap() {
        try? FileManager.default.createDirectory(
            at: directoryURL, withIntermediateDirectories: true
        )
        scan()
        seedIfEmpty()
        watcher = DirectoryWatcher(url: directoryURL) { [weak self] in
            self?.handleDirectoryChange()
        }
        watcher?.start()
    }

    /// 测试用：确定性地停掉 FSEvent 流 + 防抖 timer（生产走 deinit）。
    func shutdownForTests() {
        watcher?.stop()
        watcher = nil
        saveTimers.values.forEach { $0.invalidate() }
        saveTimers.removeAll()
    }

    // MARK: - Scan

    private func scan() {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey]
        ) else { return }

        var loaded: [NoteFile] = []
        for url in urls where url.pathExtension == Self.ext {
            guard let raw = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let fallbackID = ULID(string: url.deletingPathExtension().lastPathComponent) ?? ULID()
            let attrs = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            let created = attrs?.creationDate ?? Date()
            let updated = attrs?.contentModificationDate ?? Date()
            let note = FrontmatterCodec.decode(
                raw, fallbackID: fallbackID, fileDates: (created, updated)
            )
            loaded.append(note)
            lastWritten[note.id] = raw
        }
        notes = Self.sorted(loaded)
    }

    /// 全新安装、目录空 → 放一条欢迎笔记，避免首启动空屏。
    private func seedIfEmpty() {
        guard notes.isEmpty else { return }
        let welcome = NoteFile(
            title: "Welcome to HoverNote",
            body: """
            # Welcome to HoverNote

            A Markdown notebook that slides in from the edge of your screen.

            - **⌃⇧Space** toggles this panel
            - **⌘N** new note · **⌘F** search · **⌘P** pin · **⌘⌫** delete
            - Notes live as plain `.md` files in `~/Documents/SideNote`

            > Pinned notes float to the top. Everything autosaves.

            Write something.
            """,
            pinned: true,
            tags: ["welcome"]
        )
        write(welcome)
        notes = [welcome]
    }

    // MARK: - CRUD

    @discardableResult
    func create() -> NoteFile {
        let note = NoteFile(title: "", body: "")
        write(note)
        notes = Self.sorted(notes + [note])
        return note
    }

    /// 立即保存（失焦 / ⌘S / pin 切换时调）。
    func save(_ note: NoteFile) {
        cancelScheduledSave(note.id)
        var n = note
        n.updated = Date()
        write(n)
        replace(n)
        externallyModifiedIDs.remove(n.id)
    }

    /// 防抖保存（编辑器每次按键调，0.6s 静默后落盘）。
    func scheduleSave(_ note: NoteFile) {
        replace(note)  // 内存先更新，UI 立即反映
        saveTimers[note.id]?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
            guard let self, let fresh = self.note(id: note.id) else { return }
            self.save(fresh)
        }
        saveTimers[note.id] = timer
    }

    func delete(_ note: NoteFile) {
        cancelScheduledSave(note.id)
        let url = directoryURL.appendingPathComponent(note.fileName)
        let fm = FileManager.default
        // 优先送废纸篓（可后悔）；某些卷不支持 Trash → 退回硬删除，保证「删了就没了」
        do {
            try fm.trashItem(at: url, resultingItemURL: nil)
        } catch {
            try? fm.removeItem(at: url)
        }
        lastWritten[note.id] = nil
        externallyModifiedIDs.remove(note.id)
        notes.removeAll { $0.id == note.id }
    }

    func togglePin(_ note: NoteFile) {
        var n = note
        n.pinned.toggle()
        save(n)
    }

    /// 用户在冲突条选「保留磁盘版」：把磁盘内容读回内存，清标记。
    func reloadFromDisk(_ id: ULID) {
        let url = directoryURL.appendingPathComponent("\(id).md")
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return }
        let attrs = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        let note = FrontmatterCodec.decode(
            raw,
            fallbackID: id,
            fileDates: (attrs?.creationDate ?? Date(), attrs?.contentModificationDate ?? Date())
        )
        lastWritten[id] = raw
        replace(note)
        externallyModifiedIDs.remove(id)
    }

    // MARK: - Lookup

    func note(id: ULID) -> NoteFile? { notes.first { $0.id == id } }

    func filtered(_ query: String) -> [NoteFile] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return notes }
        return notes.filter { n in
            n.title.lowercased().contains(q)
                || n.tags.contains { $0.lowercased().contains(q) }
        }
    }

    // MARK: - Write

    private func write(_ note: NoteFile) {
        let content = FrontmatterCodec.encode(note)
        let url = directoryURL.appendingPathComponent(note.fileName)
        do {
            try content.data(using: .utf8)?.write(to: url, options: .atomic)
            lastWritten[note.id] = content
        } catch {
            NSLog("[HoverNote] write failed for \(note.fileName): \(error)")
        }
    }

    private func replace(_ note: NoteFile) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx] = note
            notes = Self.sorted(notes)
        } else {
            notes = Self.sorted(notes + [note])
        }
    }

    private func cancelScheduledSave(_ id: ULID) {
        saveTimers[id]?.invalidate()
        saveTimers[id] = nil
    }

    // MARK: - External change

    private func handleDirectoryChange() {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: directoryURL, includingPropertiesForKeys: nil
        ) else { return }

        let mdURLs = urls.filter { $0.pathExtension == Self.ext }
        let diskIDs = Set(mdURLs.compactMap {
            ULID(string: $0.deletingPathExtension().lastPathComponent)
        })

        // 删除：磁盘没了但内存还有
        for n in notes where !diskIDs.contains(n.id) {
            notes.removeAll { $0.id == n.id }
            lastWritten[n.id] = nil
        }

        for url in mdURLs {
            guard
                let id = ULID(string: url.deletingPathExtension().lastPathComponent),
                let raw = try? String(contentsOf: url, encoding: .utf8)
            else { continue }

            // 我们自己刚写的 → 跳过，不算外部修改
            if lastWritten[id] == raw { continue }

            let attrs = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            let note = FrontmatterCodec.decode(
                raw,
                fallbackID: id,
                fileDates: (attrs?.creationDate ?? Date(), attrs?.contentModificationDate ?? Date())
            )
            let isNew = !notes.contains { $0.id == id }
            lastWritten[id] = raw
            replace(note)
            // 新增文件不算冲突；已有文件被外部改 → 仅当它正被打开时打标记
            if !isNew, editingID == id {
                externallyModifiedIDs.insert(id)
            }
        }
    }

    // MARK: - Sort

    /// pinned 优先，组内按 updated 倒序。
    private static func sorted(_ list: [NoteFile]) -> [NoteFile] {
        list.sorted { a, b in
            if a.pinned != b.pinned { return a.pinned }
            return a.updated > b.updated
        }
    }
}
