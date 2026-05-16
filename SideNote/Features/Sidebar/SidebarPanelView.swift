import SwiftUI

// MARK: - Host (NSPanel 内的顶层 SwiftUI 视图)

/// NSPanel 的 contentView 渲染这个 host。它的作用：
/// - 整体占 panel 全宽 = `PanelGeometry.totalWidth`（visibleWidth + slideBuffer）
/// - HStack + Spacer 把可见 surface 推到右边
/// - 通过 `.offset(x:)` 实现 surface 的滑入/滑出
///
/// 当 `controller.isPresented = false`：surface offset +slideBuffer → 滑出 panel 右侧
/// 当 `controller.isPresented = true`：surface offset 0 → 紧贴 panel 右边、完全可见
///
/// 关键：整个 surface（包括 vibrancy + tint + wash + 内容）一起 slide。
/// 单个 SwiftUI spring 时钟，无 NSAnimationContext，无两层时序割裂。
struct SidebarPanelHost: View {

    @Bindable var controller: PanelController
    let store: NoteStore

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            SidebarPanelView()
                .environment(store)
                .frame(
                    width: PanelGeometry.visibleWidth,
                    height: PanelGeometry.visibleHeight
                )
                // ---- 边框：让"软件边界"明确 ----
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .stroke(Color.black.opacity(0.18), lineWidth: 1)
                }
                // ---- 阴影：三层堆叠，模拟自然光照 ----
                .shadow(color: .black.opacity(0.06), radius: 3,  x: 0, y: 1)   // contact
                .shadow(color: .black.opacity(0.10), radius: 9,  x: 0, y: 3)   // mid
                .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 8)   // ambient
                .padding(.trailing, PanelGeometry.shadowMargin)
                .offset(x: controller.isPresented ? 0 : PanelGeometry.slideBuffer)
        }
        .frame(
            width: PanelGeometry.totalWidth,
            height: PanelGeometry.totalHeight
        )
    }
}

// MARK: - Surface (visible 380×720 sidebar)

/// 可见侧边栏面板。3 层玻璃合成（DESIGN.md），内容由 `NoteStore` 驱动。
/// 单列导航：列表 ↔ 详情同区域切换。
struct SidebarPanelView: View {

    @Environment(NoteStore.self) private var store

    @State private var query = ""
    @State private var selectedID: ULID?
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            // ---- Layer 1: SwiftUI 原生玻璃材质 ----
            Rectangle().fill(.regularMaterial)
            // ---- Layer 2: sage 染色层（10%）----
            Color.glassSageTint.opacity(0.10)
            // ---- Layer 3: 暖白 wash（20%）----
            Color.glassWarmWash.opacity(0.20)

            content

            shortcutLayer
        }
        .frame(
            width: PanelGeometry.visibleWidth,
            height: PanelGeometry.visibleHeight
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        ZStack {
            if let id = selectedID, store.note(id: id) != nil {
                NoteDetailView(noteID: id) {
                    withAnimation(.viewSwap) { selectedID = nil }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                listScreen
                    .transition(.opacity)
            }
        }
    }

    private var listScreen: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, Spacing.lg)
                .padding(.top, 18)
                .padding(.bottom, 14)

            Divider().overlay(.faintLine)

            NoteListView(notes: store.filtered(query)) { note in
                withAnimation(.viewSwap) { selectedID = note.id }
            }

            Divider().overlay(.faintLine)

            footer
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.textMuted)

            TextField("Search notes…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(.textPrimary)
                .focused($searchFocused)

            if !query.isEmpty {
                Button { withAnimation(.cardState) { query = "" } } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.textFaint)
                }
                .buttonStyle(PressableButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(searchFocused ? 0.02 : 0.035))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md - 2, style: .continuous)
                .stroke(searchFocused ? Color.sage.opacity(0.55) : Color.hairline,
                        lineWidth: searchFocused ? 1.5 : BorderWidth.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md - 2, style: .continuous))
        .shadow(color: Color.sage.opacity(searchFocused ? 0.16 : 0),
                radius: searchFocused ? 5 : 0)
        .animation(.cardState, value: searchFocused)
    }

    private var footer: some View {
        HStack {
            Button(action: newNote) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .regular))
                    Text("New note")
                        .font(Typography.button)
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.sage)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
            }
            .buttonStyle(SagePrimaryButtonStyle())

            Spacer()

            Text("\(store.notes.count) notes · \(store.notes.filter(\.pinned).count) pinned")
                .font(Typography.meta)
                .tracking(0.4)
                .foregroundStyle(.textFaint)
        }
    }

    // MARK: - Shortcuts

    /// ⌘N 新建 / ⌘F 搜索 / ⌘P pin / ⌘⌫ 删除。藏在 0 尺寸层里靠 keyboardShortcut 触发。
    private var shortcutLayer: some View {
        ZStack {
            Button(action: newNote) { }
                .keyboardShortcut("n", modifiers: .command)
            Button { selectedID = nil; searchFocused = true } label: { }
                .keyboardShortcut("f", modifiers: .command)
            Button(action: togglePinSelected) { }
                .keyboardShortcut("p", modifiers: .command)
            Button(action: deleteSelected) { }
                .keyboardShortcut(.delete, modifiers: .command)
        }
        .opacity(0)
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)
    }

    // MARK: - Actions

    private func newNote() {
        let note = store.create()
        query = ""
        withAnimation(.viewSwap) { selectedID = note.id }
    }

    private func togglePinSelected() {
        guard let id = selectedID, let n = store.note(id: id) else { return }
        store.togglePin(n)
    }

    private func deleteSelected() {
        guard let id = selectedID, let n = store.note(id: id) else { return }
        store.delete(n)
        withAnimation(.viewSwap) { selectedID = nil }
    }
}
