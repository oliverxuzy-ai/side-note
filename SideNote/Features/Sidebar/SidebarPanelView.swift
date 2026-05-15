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

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            SidebarPanelView()
                .frame(
                    width: PanelGeometry.visibleWidth,
                    height: PanelGeometry.visibleHeight
                )
                // NOTE: 不要在这里加 SwiftUI `.shadow`。`.shadow` 会让 SwiftUI 把整个
                // view 栅格化成静态位图来算阴影 —— 这会把里面的 NSVisualEffectView
                // 冻成一张快照（=毛玻璃失活）。阴影会在 M3 polish 时通过 CALayer
                // 级别的方式加回来（PanelController 里给 hosting view 的 layer
                // 设置 shadowOpacity/Radius/Offset，那是 GPU 渲染、不栅格化）。
                .offset(x: controller.isPresented ? 0 : PanelGeometry.slideBuffer)
        }
        .frame(
            width: PanelGeometry.totalWidth,
            height: PanelGeometry.totalHeight
        )
    }
}

// MARK: - Surface (visible 380×720 sidebar)

/// 可见侧边栏面板。Static 视图，不感知 controller 状态——slide 由外层 Host 通过
/// offset 驱动。
///
/// **3 层玻璃合成**（DESIGN.md M1 升级后）：
/// 1. NSVisualEffectView (.sidebar, .behindWindow) — 桌面壁纸透过来
/// 2. sage tint @ 12% — 把 App 往 sage 方向轻微拉
/// 3. warm white wash @ 45% — 保证 readability
///
/// 净可见 ≈ 50% 桌面 + 12% sage + 45% 暖白
struct SidebarPanelView: View {

    var body: some View {
        ZStack {
            // ---- 3-layer glass composition ----
            VisualEffectBackground(material: .sidebar)
            Color.glassSageTint.opacity(0.12)
            Color.glassWarmWash.opacity(0.45)

            // ---- content ----
            contentLayer
        }
        .frame(
            width: PanelGeometry.visibleWidth,
            height: PanelGeometry.visibleHeight
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }

    // MARK: - Content

    private var contentLayer: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, Spacing.lg)
                .padding(.top, 18)
                .padding(.bottom, 14)

            Divider().overlay(.faintLine)

            notesList

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

            Text("Search notes…")
                .font(.system(size: 13))
                .foregroundStyle(.textFaint)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.035))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md - 2, style: .continuous)
                .stroke(.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md - 2, style: .continuous))
    }

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(MockNote.samples) { note in
                    NoteCard(note: note)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.never)
    }

    private var footer: some View {
        HStack {
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .regular))
                    Text("New note")
                        .font(.system(size: 12.5, weight: .medium))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.sage)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(MockNote.samples.count) notes · \(MockNote.samples.filter(\.pinned).count) pinned")
                .font(.system(size: 11))
                .tracking(0.4)
                .foregroundStyle(.textFaint)
        }
    }
}

// MARK: - Preview

#Preview("Sidebar surface (no slide — preview can't host NSPanel)") {
    SidebarPanelView()
        .frame(width: PanelGeometry.visibleWidth, height: PanelGeometry.visibleHeight)
        .background(LinearGradient(
            colors: [.gray.opacity(0.7), .brown.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
        .padding(40)
}
