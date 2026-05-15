import Foundation

/// YAML frontmatter (子集) ↔ `NoteFile` 编解码。
///
/// **为什么不用 Yams**：frontmatter 只有 6 个扁平字段，格式完全由我们自己写自己读。
/// 引一个工业级 YAML parser 是过度依赖。这里手写一个**严格但容错**的 codec：
/// - 写：标题永远加双引号（`:`、emoji、前导空格全部安全）
/// - 读：宽容——没有 frontmatter / 空 frontmatter / 手改过格式都能恢复，不抛错
///
/// 磁盘格式：
/// ```
/// ---
/// id: 01J9Z...
/// title: "标题里可以有: 冒号和 😀"
/// pinned: true
/// tags: [work, urgent]
/// created: 2026-05-15T10:30:00Z
/// updated: 2026-05-15T11:00:00Z
/// ---
///
/// <markdown body>
/// ```
enum FrontmatterCodec {

    private static let fence = "---"

    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - Encode

    static func encode(_ note: NoteFile) -> String {
        var fm = fence + "\n"
        fm += "id: \(note.id)\n"
        fm += "title: \(quote(note.title))\n"
        fm += "pinned: \(note.pinned)\n"
        fm += "tags: [\(note.tags.map(quoteTag).joined(separator: ", "))]\n"
        fm += "created: \(dateFormatter.string(from: note.created))\n"
        fm += "updated: \(dateFormatter.string(from: note.updated))\n"
        fm += fence + "\n\n"
        return fm + note.body
    }

    // MARK: - Decode

    /// `fallbackID` / `fileDates` 在 frontmatter 缺失或损坏时兜底
    /// （id 来自文件名，dates 来自文件系统 mtime）。
    static func decode(
        _ content: String,
        fallbackID: ULID,
        fileDates: (created: Date, updated: Date)
    ) -> NoteFile {

        let lines = content.components(separatedBy: "\n")

        // 必须以 `---` 开头才认为有 frontmatter
        guard lines.first?.trimmingCharacters(in: .whitespaces) == fence else {
            return decodeBare(content, id: fallbackID, dates: fileDates)
        }

        // 找闭合 `---`
        var closing: Int?
        for i in 1..<lines.count where lines[i].trimmingCharacters(in: .whitespaces) == fence {
            closing = i
            break
        }
        guard let end = closing else {
            return decodeBare(content, id: fallbackID, dates: fileDates)
        }

        var map: [String: String] = [:]
        for i in 1..<end {
            let line = lines[i]
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            if !key.isEmpty { map[key] = value }
        }

        // body = 闭合 fence 之后，跳过恰好一个紧邻空行
        var bodyStart = end + 1
        if bodyStart < lines.count, lines[bodyStart].trimmingCharacters(in: .whitespaces).isEmpty {
            bodyStart += 1
        }
        let body = bodyStart < lines.count
            ? lines[bodyStart...].joined(separator: "\n")
            : ""

        let id = map["id"].flatMap(ULID.init(string:)) ?? fallbackID
        let created = map["created"].flatMap(dateFormatter.date(from:)) ?? fileDates.created
        let updated = map["updated"].flatMap(dateFormatter.date(from:)) ?? fileDates.updated

        return NoteFile(
            id: id,
            title: unquote(map["title"] ?? ""),
            body: body,
            pinned: (map["pinned"]?.lowercased() == "true"),
            tags: parseTags(map["tags"] ?? "[]"),
            created: created,
            updated: updated
        )
    }

    /// 无 frontmatter（用户在别的编辑器里新建的纯 .md）：整文件当 body，
    /// 标题取第一行（H1 去掉 `#`，否则首非空行截断）。
    private static func decodeBare(
        _ content: String,
        id: ULID,
        dates: (created: Date, updated: Date)
    ) -> NoteFile {
        var title = ""
        for raw in content.components(separatedBy: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if line.hasPrefix("#") {
                title = line.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
            } else {
                title = String(line.prefix(80))
            }
            break
        }
        return NoteFile(
            id: id,
            title: title,
            body: content,
            pinned: false,
            tags: [],
            created: dates.created,
            updated: dates.updated
        )
    }

    // MARK: - Scalars

    private static func quote(_ s: String) -> String {
        let escaped = s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
        return "\"\(escaped)\""
    }

    private static func unquote(_ s: String) -> String {
        var v = s
        if v.hasPrefix("\"") && v.hasSuffix("\"") && v.count >= 2 {
            v = String(v.dropFirst().dropLast())
        }
        return v
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }

    private static func quoteTag(_ t: String) -> String {
        let needsQuote = t.contains(",") || t.contains("]") || t.contains("[")
            || t.contains("\"") || t != t.trimmingCharacters(in: .whitespaces)
        return needsQuote ? quote(t) : t
    }

    private static func parseTags(_ raw: String) -> [String] {
        var s = raw.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("[") { s.removeFirst() }
        if s.hasSuffix("]") { s.removeLast() }
        guard !s.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return s.components(separatedBy: ",")
            .map { unquote($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }
    }
}
