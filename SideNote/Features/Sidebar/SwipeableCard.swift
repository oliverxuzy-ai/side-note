import SwiftUI

/// 笔记卡片的滑动操作：右滑 → pin / unpin，左滑 → 删除。
///
/// 手写（不引库）：DragGesture 控水平 offset，松手按阈值决定——
/// 越过 commit 阈值直接执行；越过 reveal 阈值停在露出态（再点按钮确认）；
/// 否则 spring 弹回。手感参数走 DESIGN.md motion token。
/// 删除背景用 text-primary 近黑（不是红——sage 单色系统锁，无暖色），
/// 靠图标 + 深色对比传达"破坏性"。
struct SwipeableCard: View {

    let note: NoteFile
    let onTap: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @GestureState private var dragging = false

    private let reveal: CGFloat = 76      // 露出操作按钮的停靠位
    private let commit: CGFloat = 150     // 越过即直接执行

    var body: some View {
        ZStack {
            actionLayer
            NoteCard(note: note)
                .offset(x: offset)
                .gesture(drag)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if offset == 0 { onTap() } else { snapBack() }
                    }
                )
        }
        .animation(.viewSwap, value: offset)
    }

    // MARK: - Action backgrounds

    private var actionLayer: some View {
        HStack(spacing: 0) {
            // 右滑露出（在左侧）：pin
            action(
                icon: note.pinned ? "pin.slash.fill" : "pin.fill",
                label: note.pinned ? "Unpin" : "Pin",
                tint: Color.sage,
                visible: offset > 0
            ) { commitPin() }
            .frame(width: max(offset, 0))

            Spacer(minLength: 0)

            // 左滑露出（在右侧）：delete
            action(
                icon: "trash.fill",
                label: "Delete",
                tint: Color.textPrimary,
                visible: offset < 0
            ) { commitDelete() }
            .frame(width: max(-offset, 0))
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private func action(icon: String, label: String, tint: Color,
                        visible: Bool, perform: @escaping () -> Void) -> some View {
        ZStack {
            tint
            if visible {
                Button(action: perform) {
                    VStack(spacing: 3) {
                        Image(systemName: icon).font(.system(size: 15, weight: .medium))
                        Text(label).font(Typography.meta)
                    }
                    .foregroundStyle(Color.white)
                    .scaleEffect(min(1, abs(offset) / reveal))
                    .opacity(Double(min(1, abs(offset) / (reveal * 0.7))))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    // MARK: - Gesture

    private var drag: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($dragging) { _, s, _ in s = true }
            .onChanged { v in
                // 主要水平才接管，避免和竖直滚动打架
                guard abs(v.translation.width) > abs(v.translation.height) else { return }
                offset = rubberband(v.translation.width)
            }
            .onEnded { v in
                let x = v.translation.width
                if x > commit { commitPin() }
                else if x < -commit { commitDelete() }
                else if x > reveal * 0.6 { settle(reveal) }
                else if x < -reveal * 0.6 { settle(-reveal) }
                else { snapBack() }
            }
    }

    /// 越界后增加阻尼，像 iOS 列表那样"拉得动但越来越沉"。
    private func rubberband(_ x: CGFloat) -> CGFloat {
        if abs(x) <= commit { return x }
        let over = abs(x) - commit
        return (x < 0 ? -1 : 1) * (commit + over * 0.35)
    }

    private func settle(_ to: CGFloat) {
        withAnimation(.viewSwap) { offset = to }
    }
    private func snapBack() {
        withAnimation(.viewSwap) { offset = 0 }
    }
    private func commitPin() {
        withAnimation(.viewSwap) { offset = 0 }
        onPin()
    }
    private func commitDelete() {
        withAnimation(.slideOut) { offset = -600 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { onDelete() }
    }
}
