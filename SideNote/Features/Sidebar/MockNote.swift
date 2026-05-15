import Foundation

/// M1 hardcoded sample data. Replaced in M2 by `NoteFile` loaded from disk.
struct MockNote: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let preview: String
    let tag: String
    let timestamp: String
    let pinned: Bool
    let selected: Bool
}

extension MockNote {
    static let samples: [MockNote] = [
        .init(
            title: "Morning standup — what to flag",
            preview: "The auth refactor is blocking eng-2's work. Need to either land the small-fix PR today or scope out a quicker workaround for the demo on Thursday.",
            tag: "work",
            timestamp: "updated 2h ago",
            pinned: true,
            selected: false
        ),
        .init(
            title: "side-note · M1 slide-in spike",
            preview: "The body test of all body tests. If shoulders relax when the panel slides out, this project lives. If not, we re-think the north star.",
            tag: "design",
            timestamp: "just now",
            pinned: false,
            selected: true
        ),
        .init(
            title: "Book — Bird by Bird",
            preview: "Anne Lamott on shitty first drafts. Quote: \"you have to start somewhere, and you have to start writing it, no matter how bad.\"",
            tag: "reading",
            timestamp: "yesterday",
            pinned: false,
            selected: false
        ),
        .init(
            title: "Groceries",
            preview: "olive oil · sourdough · the small kind of tomatoes · coffee beans (whole, the bag with the orange label)",
            tag: "life",
            timestamp: "3d ago",
            pinned: false,
            selected: false
        ),
    ]
}
