import XCTest
@testable import SideNote

/// NoteStore 磁盘往返集成测试。直接打温度目录，绕开 `~/Documents` 的 TCC 同意框，
/// 验证「数据不丢」DoD：写盘 → 全新 store 重新扫描 → 内容仍在。
@MainActor
final class NoteStoreTests: XCTestCase {

    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sn-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func testCreateSaveSurvivesFreshStore() {
        let a = NoteStore(directoryURL: dir)
        var note = a.create()
        note.title = "Persisted note"
        note.body = "# Persisted\n\nbody text"
        note.tags = ["work"]
        a.save(note)

        // 全新 store（模拟 App 关掉再开）
        let b = NoteStore(directoryURL: dir)
        b.bootstrap()
        XCTAssertEqual(b.notes.count, 1)
        let reloaded = b.notes[0]
        XCTAssertEqual(reloaded.id, note.id)
        XCTAssertEqual(reloaded.title, "Persisted note")
        XCTAssertEqual(reloaded.body, "# Persisted\n\nbody text")
        XCTAssertEqual(reloaded.tags, ["work"])
        b.shutdownForTests()
    }

    func testPinPersistsAndSortsFirst() {
        let a = NoteStore(directoryURL: dir)
        let first = a.create()
        let second = a.create()
        a.togglePin(second)

        let b = NoteStore(directoryURL: dir)
        b.bootstrap()
        XCTAssertEqual(b.notes.count, 2)
        XCTAssertEqual(b.notes.first?.id, second.id, "pinned note floats to top after reload")
        XCTAssertTrue(b.notes.first?.pinned ?? false)
        XCTAssertFalse(b.notes.contains { $0.id == first.id && $0.pinned })
        b.shutdownForTests()
    }

    func testDeleteRemovesFromDisk() {
        let a = NoteStore(directoryURL: dir)
        let note = a.create()
        XCTAssertEqual(a.notes.count, 1)
        a.delete(note)
        XCTAssertEqual(a.notes.count, 0)

        let b = NoteStore(directoryURL: dir)
        b.bootstrap()
        // 删除后只剩 bootstrap 的 seed（说明原笔记确实不在磁盘了）
        XCTAssertFalse(b.notes.contains { $0.id == note.id })
        b.shutdownForTests()
    }

    func testSearchFiltersByTitleAndTag() {
        let a = NoteStore(directoryURL: dir)
        var n1 = a.create(); n1.title = "Grocery list"; a.save(n1)
        var n2 = a.create(); n2.title = "Standup";  n2.tags = ["work"]; a.save(n2)

        XCTAssertEqual(a.filtered("grocery").count, 1)
        XCTAssertEqual(a.filtered("work").first?.id, n2.id)
        XCTAssertEqual(a.filtered("").count, 2)
        XCTAssertEqual(a.filtered("nomatch").count, 0)
        a.shutdownForTests()
    }
}
