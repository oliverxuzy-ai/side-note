import SwiftUI

/// 极简偏好设置。v1 只有一项：边缘悬停触发开关（默认关）。
///
/// 开关打开时如果还没拿到 Accessibility 权限，给出引导：一句话 + 两个按钮
/// （请求权限 / 打开系统设置）。被拒绝也不崩——只是开关不生效，文案说明。
struct PreferencesView: View {

    /// 持久化在 UserDefaults，AppDelegate 监听同一 key 决定 tap 起停。
    @AppStorage("edgeHoverEnabled") private var edgeHoverEnabled = false

    /// 由宿主注入：开关变化时重新配置服务；查询当前 AX 信任态。
    let onToggle: (Bool) -> Void
    let isAXTrusted: () -> Bool
    let requestAX: () -> Void

    @State private var axTrusted = false
    @State private var hotkeyDisplay = RevealHotkey.displayString

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Preferences")
                .font(Typography.h2)
                .foregroundStyle(.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Reveal shortcut")
                    .font(Typography.body)
                    .foregroundStyle(.textPrimary)
                HotkeyRecorderField(
                    onCapture: { combo in
                        RevealHotkey.save(combo)
                        hotkeyDisplay = combo.description
                    },
                    display: hotkeyDisplay
                )
                .frame(height: 30)
                Text("Click, then press a new combo (needs ⌘/⌃/⌥). Esc cancels · ⌫ resets.")
                    .font(Typography.meta)
                    .foregroundStyle(.textMuted)
            }

            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $edgeHoverEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reveal on screen-edge hover")
                            .font(Typography.body)
                            .foregroundStyle(.textPrimary)
                        Text("Rest the cursor at the right edge to slide the panel in.")
                            .font(Typography.meta)
                            .foregroundStyle(.textMuted)
                    }
                }
                .toggleStyle(.switch)
                .tint(.sage)
                .onChange(of: edgeHoverEnabled) { _, newValue in
                    if newValue && !isAXTrusted() { requestAX() }
                    onToggle(newValue)
                    axTrusted = isAXTrusted()
                }

                if edgeHoverEnabled && !axTrusted {
                    permissionGuidance
                }
            }

            Spacer()

            Text("\(hotkeyDisplay) or the menu-bar icon always work, with or without this.")
                .font(Typography.meta)
                .foregroundStyle(.textFaint)
        }
        .padding(24)
        .frame(width: 380, height: 380)
        .background(Color.canvas)
        .onAppear { axTrusted = isAXTrusted() }
    }

    private var permissionGuidance: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Needs Accessibility permission")
                .font(Typography.button)
                .foregroundStyle(.sageDeep)
            Text("HoverNote watches the cursor position to detect the edge. Grant access in System Settings → Privacy & Security → Accessibility.")
                .font(Typography.meta)
                .foregroundStyle(.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Button("Request permission") { requestAX(); axTrusted = isAXTrusted() }
                Button("Open Accessibility Settings") {
                    EdgeHoverService.openAccessibilitySettings()
                }
            }
            .font(Typography.button)
            .buttonStyle(PressableButtonStyle())
            .foregroundStyle(.sageDeep)
        }
        .padding(12)
        .background(Color.sageSoft.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}
