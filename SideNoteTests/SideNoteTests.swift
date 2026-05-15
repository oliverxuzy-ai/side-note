import XCTest
import Markdown
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

    // MARK: - Markdown subset parses

    func testEightSupportedBlockKindsParse() {
        let md = """
        # H1
        ## H2
        ### H3

        A paragraph with **bold**, *italic*, `code` and [a link](https://example.com).

        - bullet one
        - bullet two

        1. first
        2. second

        > a quote

        ```
        let x = 1
        ```
        """
        let doc = Document(parsing: md)
        let kinds = doc.blockChildren.map { String(describing: type(of: $0)) }
        XCTAssertTrue(kinds.contains("Heading"))
        XCTAssertTrue(kinds.contains("Paragraph"))
        XCTAssertTrue(kinds.contains("UnorderedList"))
        XCTAssertTrue(kinds.contains("OrderedList"))
        XCTAssertTrue(kinds.contains("BlockQuote"))
        XCTAssertTrue(kinds.contains("CodeBlock"))
    }

    func testUnsupportedSyntaxDoesNotCrashAndKeepsText() {
        // 表格不在 v1 子集，渲染层会原样显示 format()——这里只验证解析不丢内容
        let md = "| a | b |\n|---|---|\n| 1 | 2 |"
        let doc = Document(parsing: md)
        XCTAssertFalse(doc.format().isEmpty)
    }
}
