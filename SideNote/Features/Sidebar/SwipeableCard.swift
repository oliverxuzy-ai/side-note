import SwiftUI
import AppKit

/// 笔记卡片滑动操作：右滑 → pin/unpin，左滑 → 删除。
///
/// **Mac 原生手势**：用 `NSPanGestureRecognizer` + `allowedScrollTypesMask = .continuous`，
/// 鼠标按住拖 **和触控板双指横扫**都识别（SwiftUI 的 `DragGesture` 不认双指 scroll）。
/// 竖直为主的手势放行给外层列表滚动。Mail 式整段滑过即执行，不做停靠态。
/// 删除背景用近黑（sage 单色锁，无红）。
struct SwipeableCard: View {

    let note: NoteFile
    let onTap: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0

    private let commit: CGFloat = 110     // 越过即执行

    var body: some View {
        ZStack {
            actionLayer
            NoteCard(note: note)
                .offset(x: offset)
                .overlay(
                    SwipeCatcher(
                        offset: $offset,
                        commit: commit,
                        onTap: onTap,
                        onPin: { fire(pin: true) },
                        onDelete: { fire(pin: false) }
                    )
                )
        }
        .animation(.viewSwap, value: offset)
    }

    // MARK: - Action backgrounds

    private var actionLayer: some View {
        HStack(spacing: 0) {
            if offset > 0.5 {
                actionTile(
                    icon: note.pinned ? "pin.slash.fill" : "pin.fill",
                    label: note.pinned ? "Unpin" : "Pin",
                    tint: Color.sage,
                    width: offset,
                    progress: min(1, offset / commit)
                )
            }
            Spacer(minLength: 0)
            if offset < -0.5 {
                actionTile(
                    icon: "trash.fill",
                    label: "Delete",
                    tint: Color.textPrimary,
                    width: -offset,
                    progress: min(1, -offset / commit)
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private func actionTile(icon: String, label: String, tint: Color,
                            width: CGFloat, progress: CGFloat) -> some View {
        ZStack {
            tint
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 15, weight: .medium))
                Text(label).font(Typography.meta)
            }
            .foregroundStyle(Color.white)
            .scaleEffect(0.85 + 0.15 * progress)
            .opacity(Double(progress))
        }
        .frame(width: width)
        .clipped()
    }

    private func fire(pin: Bool) {
        if pin {
            withAnimation(.viewSwap) { offset = 0 }
            onPin()
        } else {
            withAnimation(.slideOut) { offset = -700 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { onDelete() }
        }
    }
}

// MARK: - AppKit gesture catcher

/// 两条输入路径：
/// - **鼠标按住拖** → `NSPanGestureRecognizer`（AppKit 原生支持鼠标 pan）
/// - **触控板双指横扫** → 自定义 `scrollWheel(with:)`（AppKit 的 pan recognizer
///   不识别 scroll 事件，UIKit 的 `allowedScrollTypesMask` 在 macOS 不存在，
///   双指必须走 scrollWheel）
/// 竖直为主的手势放行给外层列表滚动；轻点 → 打开。
private struct SwipeCatcher: NSViewRepresentable {

    @Binding var offset: CGFloat
    let commit: CGFloat
    let onTap: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSView {
        let v = SwipeCatcherView()
        v.coordinator = context.coordinator
        v.wantsLayer = true

        let pan = NSPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        v.addGestureRecognizer(pan)

        let click = NSClickGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.handleClick))
        click.delaysPrimaryMouseButtonEvents = false
        v.addGestureRecognizer(click)

        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject {
        var parent: SwipeCatcher
        private var axis: Axis? = nil
        private var scrollAccumX: CGFloat = 0
        enum Axis { case horizontal, vertical }

        init(_ parent: SwipeCatcher) { self.parent = parent }

        @objc func handleClick() {
            if parent.offset == 0 { parent.onTap() }
            else { withAnimation(.viewSwap) { parent.offset = 0 } }
        }

        // --- 鼠标拖拽 ---
        @objc func handlePan(_ gr: NSPanGestureRecognizer) {
            guard let view = gr.view else { return }
            let t = gr.translation(in: view)
            switch gr.state {
            case .began:
                axis = nil
            case .changed:
                if axis == nil, abs(t.x) > 6 || abs(t.y) > 6 {
                    axis = abs(t.x) > abs(t.y) ? .horizontal : .vertical
                }
                if axis == .horizontal { parent.offset = rubberband(t.x) }
            case .ended, .cancelled, .failed:
                defer { axis = nil }
                guard axis == .horizontal else { return }
                resolve(t.x)
            default:
                break
            }
        }

        // --- 触控板双指（由 SwipeCatcherView.scrollWheel 调用）---
        /// 返回 true = 本事件被横向滑动消费；false = 放行给列表滚动
        func handleScroll(phase: NSEvent.Phase, dx: CGFloat, dy: CGFloat) -> Bool {
            if phase.contains(.began) {
                axis = nil
                scrollAccumX = 0
            }
            if axis == nil {
                scrollAccumX += dx
                if abs(scrollAccumX) > 5 || abs(dy) > 5 {
                    axis = abs(scrollAccumX) > abs(dy) ? .horizontal : .vertical
                }
            }
            guard axis == .horizontal else { return false }
            if phase.contains(.ended) || phase.contains(.cancelled) {
                let final = parent.offset
                axis = nil
                resolve(final)
            } else {
                parent.offset = rubberband(parent.offset + dx)
            }
            return true
        }

        private func resolve(_ x: CGFloat) {
            if x > parent.commit { parent.onPin() }
            else if x < -parent.commit { parent.onDelete() }
            else { withAnimation(.viewSwap) { parent.offset = 0 } }
        }

        private func rubberband(_ x: CGFloat) -> CGFloat {
            let c = parent.commit
            guard abs(x) > c else { return x }
            let over = abs(x) - c
            return (x < 0 ? -1 : 1) * (c + over * 0.35)
        }
    }
}

/// scrollWheel 入口。横向为主自己消费，竖向 super 放行给外层 NSScrollView。
private final class SwipeCatcherView: NSView {
    weak var coordinator: SwipeCatcher.Coordinator?

    override func scrollWheel(with event: NSEvent) {
        // 非精确（普通鼠标滚轮）= 竖直滚动，直接放行
        guard event.hasPreciseScrollingDeltas, let coordinator else {
            super.scrollWheel(with: event)
            return
        }
        let consumed = coordinator.handleScroll(
            phase: event.phase.isEmpty ? .changed : event.phase,
            dx: event.scrollingDeltaX,
            dy: event.scrollingDeltaY
        )
        if !consumed { super.scrollWheel(with: event) }
    }
}
