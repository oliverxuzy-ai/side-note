import Foundation

/// 26 字符 ULID：48-bit 毫秒时间戳 + 80-bit 随机。Crockford base32。
///
/// 选 ULID 而不是 UUID 当文件名 / id 的原因：**字典序 == 时间序**。
/// NoteStore 用它当文件名（`<ulid>.md`），目录按名字排序即按创建时间排序，
/// 不需要额外索引。同毫秒内多次创建靠随机位区分。
struct ULID: Hashable, Codable, CustomStringConvertible {

    let description: String

    /// Crockford base32 字母表（去掉 I L O U，避免和 1 0 混淆）。
    private static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")

    init() {
        self.init(timestamp: Date())
    }

    init(timestamp: Date) {
        var chars = [Character](repeating: "0", count: 26)

        // --- 时间部分：10 个字符编码 48-bit 毫秒 ---
        var ms = UInt64(max(0, timestamp.timeIntervalSince1970) * 1000)
        for i in stride(from: 9, through: 0, by: -1) {
            chars[i] = Self.alphabet[Int(ms & 0x1F)]
            ms >>= 5
        }

        // --- 随机部分：16 个字符（80-bit）---
        for i in 10..<26 {
            chars[i] = Self.alphabet[Int.random(in: 0..<32)]
        }

        self.description = String(chars)
    }

    /// 从已有字符串恢复（读盘时用）。不校验合法性——文件名我们自己写的。
    init?(string: String) {
        let s = string.uppercased()
        guard s.count == 26 else { return nil }
        self.description = s
    }
}
