import SwiftUI

/// 笔记列表。pinned 优先 + updated 倒序（排序在 NoteStore 里做）。
/// 搜索由父级传入的 `query` 过滤。
struct NoteListView: View {

    let notes: [NoteFile]
    let onSelect: (NoteFile) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if notes.isEmpty {
                    emptyState
                } else {
                    ForEach(notes) { note in
                        Button { onSelect(note) } label: {
                            NoteCard(note: note)
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.985))
                        .hoverLift()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.never)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No notes")
                .font(Typography.h3)
                .foregroundStyle(.textMuted)
            Text("⌘N to create one")
                .font(Typography.meta)
                .foregroundStyle(.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
