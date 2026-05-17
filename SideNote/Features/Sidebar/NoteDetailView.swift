import SwiftUI

/// 选中一条笔记后的详情：标题 + Bear 风格 live 编辑 + 外部变更冲突条。
///
/// 无 view/edit 切换——`LiveMarkdownEditor` 输入即渲染。
/// 单列导航（DESIGN.md Open Question #3 v1 倾向单列）：列表 ↔ 详情同区域切换。
/// draft 是编辑缓冲，store 是真相；改动走 scheduleSave 防抖落盘。
struct NoteDetailView: View {

    @Environment(NoteStore.self) private var store

    let noteID: ULID
    let onBack: () -> Void

    @State private var draft: NoteFile?
    @State private var pinScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            header

            if store.externallyModifiedIDs.contains(noteID) {
                conflictBanner
            }

            if draft != nil {
                bodyArea
            } else {
                Spacer()
                Text("Note not found")
                    .font(Typography.body)
                    .foregroundStyle(.textMuted)
                Spacer()
            }
        }
        .animation(.viewSwap, value: store.externallyModifiedIDs.contains(noteID))
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
            .buttonStyle(PressableButtonStyle())

            TextField("Title", text: titleBinding)
                .textFieldStyle(.plain)
                .font(Typography.h3)
                .foregroundStyle(.textPrimary)

            Spacer()

            Button {
                if let d = draft { store.togglePin(d); draft?.pinned.toggle() }
                // DESIGN.md：图钉按下 spring-fast 0.96 → 1.0
                pinScale = 0.96
                withAnimation(.pressFeedback) { pinScale = 1.0 }
            } label: {
                Image(systemName: (draft?.pinned ?? false) ? "pin.fill" : "pin")
                    .font(.system(size: 13))
                    .foregroundStyle((draft?.pinned ?? false) ? .sage : .textFaint)
                    .scaleEffect(pinScale)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    // MARK: - Body

    @ViewBuilder
    private var bodyArea: some View {
        Divider().overlay(.faintLine)

        LiveMarkdownEditor(text: bodyBinding)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, 16)
    }

    // MARK: - Conflict banner (DESIGN.md: 外部变更提示)

    private var conflictBanner: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.sageDeep)
            Text("Changed outside HoverNote")
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
        .buttonStyle(PressableButtonStyle())
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, 10)
        .background(Color.sageSoft.opacity(0.22))
        .transition(.move(edge: .top).combined(with: .opacity))
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
