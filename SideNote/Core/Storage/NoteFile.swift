import Foundation

/// 一条笔记。磁盘上 = `~/Documents/SideNote/<id>.md`，文件内 = YAML frontmatter + Markdown body。
///
/// 文件名用 id（ULID）而不是 title 的原因：标题改一次就要 rename 文件，
/// rename 触发 FSEvents 又反过来扰动 store——死循环风险。id 当文件名 = 稳定，
/// 标题完全活在 frontmatter 里，改标题只是改文件内容，不动文件名。
struct NoteFile: Identifiable, Hashable {

    let id: ULID
    var title: String
    var body: String
    var pinned: Bool
    var tags: [String]
    let created: Date
    var updated: Date

    var fileName: String { "\(id).md" }

    init(
        id: ULID = ULID(),
        title: String = "",
        body: String = "",
        pinned: Bool = false,
        tags: [String] = [],
        created: Date = Date(),
        updated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.pinned = pinned
        self.tags = tags
        self.created = created
        self.updated = updated
    }

    /// 列表卡片用的摘要：body 的第一段非空文本，去掉 Markdown 标记噪音的轻量版本。
    var preview: String {
        for rawLine in body.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if line.hasPrefix("#") || line.hasPrefix("```") { continue }
            return line
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "`", with: "")
        }
        return ""
    }

    /// 卡片右下角的相对时间戳。
    var relativeTimestamp: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: updated, relativeTo: Date())
    }

    /// 标题为空时（新建未命名）回退显示。
    var displayTitle: String {
        title.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : title
    }
}
