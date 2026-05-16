import XCTest
@testable import SideNote

/// M2 tests — storage 正确性是「数据不丢」DoD 的底线，重点覆盖 PLAN.md
/// 点名的 frontmatter corner case：含冒号标题、emoji 标题、空 / 缺失 frontmatter。
final class SideNoteTests: XCTestCase {

    private let fixedDates = (created: Date(timeIntervalSince1970: 1_700_000_000),
                              updated: Date(timeIntervalSince1970: 1_700_000_500))

    // MARK: - ULID

    func testULIDIs26CharsAndTimeSortable() {
        let early = ULID(timestamp: Date(timeIntervalSince1970: 1_000_000))
        let late  = ULID(timestamp: Date(timeIntervalSince1970: 2_000_000))
        XCTAssertEqual(early.description.count, 26)
        XCTAssertEqual(late.description.count, 26)
        // 字典序 == 时间序（NoteStore 靠这个用文件名排序）
        XCTAssertLessThan(early.description, late.description)
    }

    func testULIDRoundTripsThroughString() {
        let u = ULID()
        let restored = ULID(string: u.description)
        XCTAssertEqual(restored?.description, u.description)
        XCTAssertNil(ULID(string: "too-short"))
    }

    // MARK: - FrontmatterCodec round-trip

    func testRoundTripPreservesAllFields() {
        let original = NoteFile(
            title: "Plain title",
            body: "# Heading\n\nSome **body** text.",
            pinned: true,
            tags: ["work", "urgent"],
            created: fixedDates.created,
            updated: fixedDates.updated
        )
        let decoded = FrontmatterCodec.decode(
            FrontmatterCodec.encode(original),
            fallbackID: ULID(),
            fileDates: fixedDates
        )
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.body, original.body)
        XCTAssertEqual(decoded.pinned, true)
        XCTAssertEqual(decoded.tags, ["work", "urgent"])
        XCTAssertEqual(Int(decoded.created.timeIntervalSince1970),
                       Int(original.created.timeIntervalSince1970))
    }

    func testTitleWithColonSurvives() {
        let note = NoteFile(title: "Standup: what to flag today", body: "x")
        let decoded = FrontmatterCodec.decode(
            FrontmatterCodec.encode(note), fallbackID: ULID(), fileDates: fixedDates
        )
        XCTAssertEqual(decoded.title, "Standup: what to flag today")
    }

    func testEmojiAndQuoteInTitleSurvive() {
        let note = NoteFile(title: #"😀 "quoted" — emoji 标题"#, body: "y")
        let decoded = FrontmatterCodec.decode(
            FrontmatterCodec.encode(note), fallbackID: ULID(), fileDates: fixedDates
        )
        XCTAssertEqual(decoded.title, #"😀 "quoted" — emoji 标题"#)
    }

    func testEmptyTitleAndTagsRoundTrip() {
        let note = NoteFile(title: "", body: "body only", pinned: false, tags: [])
        let decoded = FrontmatterCodec.decode(
            FrontmatterCodec.encode(note), fallbackID: ULID(), fileDates: fixedDates
        )
        XCTAssertEqual(decoded.title, "")
        XCTAssertEqual(decoded.tags, [])
        XCTAssertEqual(decoded.body, "body only")
        XCTAssertEqual(decoded.displayTitle, "Untitled")
    }

    func testBareFileWithNoFrontmatterDerivesTitleFromHeading() {
        let id = ULID()
        let decoded = FrontmatterCodec.decode(
            "# Hand-written note\n\nWritten in another editor.",
            fallbackID: id,
            fileDates: fixedDates
        )
        XCTAssertEqual(decoded.id, id)
        XCTAssertEqual(decoded.title, "Hand-written note")
        XCTAssertTrue(decoded.body.contains("another editor"))
    }

    func testGarbledFrontmatterFallsBackToBare() {
        // 有起始 --- 但没有闭合 fence → 当作无 frontmatter，不崩
        let decoded = FrontmatterCodec.decode(
            "---\nid: broken\ntitle: no closing fence\n\nbody here",
            fallbackID: ULID(),
            fileDates: fixedDates
        )
        XCTAssertFalse(decoded.body.isEmpty)
    }

    // MARK: - Live editor tokenization

    private func cap1(_ re: NSRegularExpression, _ s: String) -> String? {
        let ns = s as NSString
        guard let m = re.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges >= 2 else { return nil }
        return ns.substring(with: m.range(at: 1))
    }

    func testInlineRegexesCaptureContent() {
        typealias C = LiveMarkdownEditor.Coordinator
        XCTAssertEqual(cap1(C.bold,   "say **hello** now"), "hello")
        XCTAssertEqual(cap1(C.code,   "use `swift` here"),  "swift")
        XCTAssertEqual(cap1(C.italic, "an _emphasis_ word"), "emphasis")
        XCTAssertEqual(cap1(C.italic, "an *emphasis* word"), "emphasis")
        XCTAssertEqual(cap1(C.link,   "see [docs](https://x.com)"), "docs")
    }

    func testBoldNotMisreadAsItalic() {
        // **x** 不应被单星斜体规则吃掉
        XCTAssertNil(cap1(LiveMarkdownEditor.Coordinator.italic, "**bold**"))
        XCTAssertEqual(cap1(LiveMarkdownEditor.Coordinator.bold, "**bold**"), "bold")
    }

    func testHeadingMatchesByLevel() {
        let h = LiveMarkdownEditor.Coordinator.heading
        for s in ["# Title", "## Sub", "### Deep"] {
            XCTAssertNotNil(h.firstMatch(in: s, range: NSRange(location: 0, length: (s as NSString).length)))
        }
        let none = "#notspace"
        XCTAssertNil(h.firstMatch(in: none, range: NSRange(location: 0, length: (none as NSString).length)))
    }

    func testTaskAndBulletTokenization() {
        typealias C = LiveMarkdownEditor.Coordinator
        func matches(_ re: NSRegularExpression, _ s: String) -> Bool {
            re.firstMatch(in: s, range: NSRange(location: 0, length: (s as NSString).length)) != nil
        }
        // task: group1 = "- " 前缀, group2 = 勾选字符
        XCTAssertEqual(cap1(C.task, "- [ ] buy milk"), "- ")
        XCTAssertEqual(cap1(C.task, "  - [x] done"), "  - ")
        XCTAssertTrue(matches(C.task, "* [X] starred"))
        XCTAssertFalse(matches(C.task, "- not a task"))
        // bullet 命中普通项但 task 行也命中 bullet → highlighter 里 task 优先判定
        XCTAssertEqual(cap1(C.bullet, "- plain item"), "-")
        XCTAssertEqual(cap1(C.bullet, "+ plus item"), "+")
        XCTAssertFalse(matches(C.bullet, "-no space"))
    }

    func testHalfTypedMarkdownDoesNotMatch() {
        // live editing 输入到一半不能误上样式 / 不能崩
        XCTAssertNil(cap1(LiveMarkdownEditor.Coordinator.bold, "**unterminated"))
        XCTAssertNil(cap1(LiveMarkdownEditor.Coordinator.code, "`open only"))
        XCTAssertNil(cap1(LiveMarkdownEditor.Coordinator.link, "[label](no-close"))
    }
}
