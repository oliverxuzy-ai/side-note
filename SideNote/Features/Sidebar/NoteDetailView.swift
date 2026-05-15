import SwiftUI

/// 选中一条笔记后的详情：标题 + 查看/编辑两态切换 + 外部变更冲突条。
///
/// 单列导航（DESIGN.md Open Question #3 v1 倾向单列）：列表 ↔ 详情同区域切换，
/// 不做双栏。draft 是编辑缓冲，store 是真相；改动走 scheduleSave 防抖落盘。
struct NoteDetailView: View {

    @Environment(NoteStore.self) private var store

    let noteID: ULID
    let onBack: () -> Void

    @State private var draft: NoteFile?
    @State private var editing = false

    var body: some View {
        VStack(spacing: 0) {
            header

            if store.externallyModifiedIDs.contains(noteID) {
                conflictBanner
            }

            if let d = draft {
                bodyArea(d)
            } else {
                Spacer()
                Text("Note not found")
                    .font(Typography.body)
                    .foregroundStyle(.textMuted)
                Spacer()
            }
        }
        .onAppear {
            draft = store.note(id: noteID)
            store.editingID = noteID
        }
        .onDisappear {
            if let d = draft { store.save(d) }
            store.editingID = nil
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.md) {
            Button(action: commitAndBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textMuted)
            }
            .buttonStyle(.plain)

            TextField("Title", text: titleBinding)
                .textFieldStyle(.plain)
                .font(Typography.h3)
                .foregroundStyle(.textPrimary)

            Spacer()

            Button {
                if let d = draft { store.togglePin(d); draft?.pinned.toggle() }
            } label: {
                Image(systemName: (draft?.pinned ?? false) ? "pin.fill" : "pin")
                    .font(.system(size: 13))
                    .foregroundStyle((draft?.pinned ?? false) ? .sage : .textFaint)
            }
            .buttonStyle(.plain)

            Button { editing.toggle() } label: {
                Image(systemName: editing ? "eye" : "pencil")
                    .font(.system(size: 13))
                    .foregroundStyle(.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    // MARK: - Body

    @ViewBuilder
    private func bodyArea(_ d: NoteFile) -> some View {
        Divider().overlay(.faintLine)

        if editing {
            MarkdownEditor(text: bodyBinding)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, 16)
        } else {
            ScrollView {
                MarkdownView(markdown: d.body)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, 18)
            }
            .scrollIndicators(.never)
        }
    }

    // MARK: - Conflict banner (DESIGN.md: 外部变更提示)

    private var conflictBanner: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.sageDeep)
            Text("Changed outside side-note")
                .font(Typography.meta)
                .foregroundStyle(.textPrimary)
            Spacer()
            Button("Keep disk") {
                store.reloadFromDisk(noteID)
                draft = store.note(id: noteID)
            }
            .font(Typography.button)
            .foregroundStyle(.sageDeep)
            Button("Keep mine") {
                if let d = draft { store.save(d) }
            }
            .font(Typography.button)
            .foregroundStyle(.textMuted)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, 10)
        .background(Color.sageSoft.opacity(0.22))
    }

    // MARK: - Bindings

    private var titleBinding: Binding<String> {
        Binding(
            get: { draft?.title ?? "" },
            set: { newValue in
                guard draft != nil else { return }
                draft?.title = newValue
                if let d = draft { store.scheduleSave(d) }
            }
        )
    }

    private var bodyBinding: Binding<String> {
        Binding(
            get: { draft?.body ?? "" },
            set: { newValue in
                guard draft != nil else { return }
                draft?.body = newValue
                if let d = draft { store.scheduleSave(d) }
            }
        )
    }

    private func commitAndBack() {
        if let d = draft { store.save(d) }
        store.editingID = nil
        onBack()
    }
}
