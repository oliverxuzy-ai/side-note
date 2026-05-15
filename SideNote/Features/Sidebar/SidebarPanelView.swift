import SwiftUI

/// M1 · 主侧边栏面板视图。
///
/// 三层结构：
/// 1. NSVisualEffectView 材质（vibrancy）
/// 2. Color.canvas at 92% opacity（sage tint，让 ~8% 桌面壁纸透过来）
/// 3. SwiftUI 内容层（search + notes list + new-note button）
///
/// 第三层挂在 `controller.isContentPresented` 上 —— 它是 spring + parallax + alpha 的动画触发源。
/// 时序由 PanelController 拍板：panel 位置开始动 80ms 后，content 才开始动。
/// 两层不同节奏 = 你眼睛看到的是「层次」而不是「位移」。
struct SidebarPanelView: View {

    /// `@Bindable` 让 SwiftUI 追踪 @Observable 类的属性变化。
    @Bindable var controller: PanelController

    var body: some View {
        ZStack {
            // ---- Layer 1: vibrancy 材质 ----
            VisualEffectBackground()

            // ---- Layer 2: 92% canvas (sage tint) ----
            Color.canvas.opacity(0.92)

            // ---- Layer 3: 内容（带 parallax + alpha） ----
            contentLayer
                .offset(x: controller.isContentPresented ? 0 : PanelGeometry.contentParallax)
                .opacity(controller.isContentPresented ? 1 : 0)
                .animation(
                    controller.isContentPresented ? .slideInContent : .slideOutContent,
                    value: controller.isContentPresented
                )
        }
        .frame(width: PanelGeometry.width, height: PanelGeometry.height)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }

    // MARK: - Content layer

    private var contentLayer: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, Spacing.lg)
                .padding(.top, 18)
                .padding(.bottom, 14)

            Divider()
                .overlay(.faintLine)

            notesList

            Divider()
                .overlay(.faintLine)

            footer
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    // MARK: - Search bar

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

    // MARK: - Notes list

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

    // MARK: - Footer

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

#Preview("Sidebar · M1 (preview only — slide-in invisible in Xcode Preview)") {
    SidebarPanelView(controller: PanelController())
        .frame(width: PanelGeometry.width, height: PanelGeometry.height)
        .onAppear {
            // Force content visible in Preview (Preview doesn't have NSPanel to trigger it)
        }
}
