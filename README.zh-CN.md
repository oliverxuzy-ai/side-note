<div align="center">

# HoverNote

**一个从屏幕边缘滑入的 Mac 侧边栏 Markdown 笔记本。**
macOS 上最安静好看的笔记 App——做不到就不值得发布。

[English](README.md) · **简体中文**

![platform](https://img.shields.io/badge/platform-macOS%2014%2B-1F1E18?style=flat-square)
![swift](https://img.shields.io/badge/Swift-5.10-6E8060?style=flat-square)
![SwiftUI](https://img.shields.io/badge/SwiftUI-native-6E8060?style=flat-square)
[![release](https://img.shields.io/github/v/release/oliverxuzy-ai/HoverNote?sort=semver&style=flat-square&color=6E8060&label=release)](https://github.com/oliverxuzy-ai/HoverNote/releases/latest)
![license](https://img.shields.io/badge/license-MIT-6E8060?style=flat-square)

</div>

> **北极星**——面板从屏幕边缘滑出的那 0.4 秒身体状态变化。这个项目的每一个
> 决策都为这一个瞬间服务。

---

## 这是什么

一个原生 macOS App（macOS 14+，SwiftUI），常驻在你的**菜单栏**，按快捷键或
鼠标贴右边缘即从屏幕右侧滑出。你写的 Markdown 输入即上样式——Bear 风格，
没有「编辑/预览」切换。卡片右滑置顶、左滑删除。关掉时，它以同样的方式滑回去。

它不想做功能最强的笔记工具，只想做那个让你肩膀松下来的。

每条笔记都是磁盘上一个带 YAML frontmatter 的纯 `.md` 文件——用 Obsidian、
Vim 或任何编辑器都能打开。无数据库、无云同步、无锁定。

---

## 安装

到 **[Releases](https://github.com/oliverxuzy-ai/HoverNote/releases/latest)**
下载最新的 **`HoverNote-x.y.z.dmg`**。

1. 双击 `.dmg` 挂载
2. 把 **HoverNote.app** 拖到 **Applications** 快捷方式上
3. **首次启动——右键 App → 打开**（弹窗里再点一次「打开」）

> 第 3 步只需做一次。HoverNote 是自签名（ad-hoc）、未公证的，所以 macOS
> Gatekeeper 第一次会拒绝直接双击。右键 → 打开 = 告诉 macOS 你信任它，
> 之后就能正常启动。公证（notarization）是 v2 的事。

**系统要求**：macOS 14.0 (Sonoma) 及以上 · Apple Silicon 与 Intel 均可。

没有 Dock 图标——HoverNote 活在**菜单栏**里。点菜单栏图标，或按你的呼出
快捷键（默认 `⌃⇧Space`）把它滑出来。

---

## 功能

- **三种呼出方式**——菜单栏图标、全局快捷键、或贴右边缘悬停（需手动开启，
  默认关；要辅助功能权限）。快捷键可在 **偏好设置里用录制器自定义**
  （默认 `⌃⇧Space`）。
- **真·滑入**——单个 SwiftUI spring 驱动整个面板；`.regularMaterial`
  实时玻璃材质透出你的桌面。
- **Live Markdown 编辑**——Bear 风格，无编辑/预览切换。标记符保留但变淡。
  H1–H3、**粗体**、*斜体*、`行内代码`、链接、围栏代码块（圆角底）、
  引用块（sage 立柱）输入即上样式。真 `•` 圆点、带正确悬挂缩进的有序列表、
  可点击的 `- [ ]` / `- [x]` 待办复选框。光标与撤销永不被打断。
- **Slash 菜单**——输入 `/` 弹出菜单：标题 1–3、无序列表、待办、有序列表、
  引用、代码块。方向键或鼠标选择，↵ 插入。
- **滑动操作**——卡片右滑置顶/取消，左滑删除。**触控板双指**和鼠标拖拽都支持。
- **纯文件存储**——原子写入、FSEvents 双向同步、外部修改冲突提示条、
  删除进废纸篓。
- **置顶笔记**——卡片上一枚小 sage 图钉；置顶笔记浮到最上。
- **标题 + 标签搜索。**
- **讲究的交互手感**——每个控件都有 hover 反馈，卡片与菜单共用同一套
  sage 选中语言，克制的动效。
- **Sage 单色系**——一个色相，任何地方都没有暖色（[`DESIGN.md`](DESIGN.md)）。

### 键盘

| 快捷键 | 动作 |
|--------|------|
| `⌃⇧Space` *(可自定义)* | 开关面板 |
| `/` | Slash 命令菜单（编辑器内） |
| `⌘N` | 新建笔记 |
| `⌘F` | 聚焦搜索 |
| `⌘P` | 置顶/取消置顶选中项 |
| `⌘⌫` | 删除选中项（进废纸篓） |
| `⌘,` | 偏好设置 |

---

## 设计系统

所有视觉规范都在 [`DESIGN.md`](DESIGN.md)。简版：

| 层 | 取值 |
|----|------|
| Canvas | SwiftUI 三层玻璃：`.regularMaterial` + sage 染色 10% + 暖白 wash 20% |
| Accent | `#6E8060` refined rosemary sage——系统里唯一的颜色 |
| Surface | `rgba(255,255,255,0.55)` 玻璃之上的半透明白卡 |
| Display | PP Editorial New *（暂未内置——回退系统衬线）* |
| Body | General Sans（Fontshare，已内置） |
| Mono | JetBrains Mono（Apache-2.0，已内置） |
| 基准单位 | 4pt（macOS HIG） |
| 滑入 | 0.42s spring · 滑出 0.22s ease-in |

改视觉代码前先读 `DESIGN.md`。没有明确记录的理由不得偏离。

---

## 从源码构建

本仓库用 [xcodegen](https://github.com/yonaskolb/XcodeGen)——Xcode 工程是
声明式的 `project.yml`，不是二进制黑盒。`SideNote.xcodeproj` 故意 gitignore。
（Xcode target / Swift 模块内部仍叫 `SideNote`，只有产品名是 **HoverNote**——
改名说明见 [`DESIGN.md`](DESIGN.md)。）

```bash
brew install xcodegen          # 一次性

xcodegen generate              # clone 后，或改了 project.yml 后
open SideNote.xcodeproj        # 然后 ⌘R
```

```bash
# 命令行，不开 Xcode UI
xcodegen generate
xcodebuild -project SideNote.xcodeproj -scheme SideNote -configuration Debug build
xcodebuild -project SideNote.xcodeproj -scheme SideNote -configuration Debug test
```

**要求**——Xcode 16+（CI 钉 latest-stable）、macOS 14.0+ 部署目标、本地开发
无需 Apple Developer 账户（ad-hoc *Sign to Run Locally*）。

### 发布是自动的

每次 push 到 `main` 都会跑 `.github/workflows/release.yml`：按 conventional
commit 自动定版（`feat` → minor，`fix` → patch；docs/chore → 不发版），
构建可直接运行的签名 `.dmg`，并发布一个公开 GitHub release。大版本是手动的
（Actions → Release → *Run workflow* → `bump = major`）。`VERSION` + `scripts/`
支撑本地路径。

---

## 技术栈

- **Swift 5.10 / SwiftUI**，最低 macOS 14.0。
- **Live Markdown**——正则高亮器 + 自定义 `NSLayoutManager`（原位画圆点/
  复选框、代码块/引用块底）。无 Markdown 库；`swift-markdown` 已移除。
- **滑动与 hover**——全手写：触控板双指走 `scrollWheel`，鼠标拖走
  `NSPanGestureRecognizer`，可靠 hover 走 `NSTrackingArea`（无 UI 库）。
- **快捷键**——[`soffes/HotKey`](https://github.com/soffes/HotKey)
  *（唯一依赖）*。
- **存储**——文件系统，`~/Documents/SideNote/<ULID>.md`。
- **边缘悬停**——`CGEventTap`（也是 v1 不上 Mac App Store 的原因）。
- 无 Rust、无 Electron、无 Tauri。原生材质本身就是重点。

---

## 范围

**做**——滑入/滑出（3 种触发，快捷键可改）、Live Markdown 编辑（含待办）、
slash 菜单、滑动置顶/删除、置顶、标签、标题+标签搜索、笔记 CRUD、浅色主题、
FSEvents 双向同步、自动化自签名 `.dmg` 发布。

**暂时不做**——深色主题（需要自己的 mood board）、云同步、iOS、AI 功能、
Mac App Store（sandbox 禁掉 `CGEventTap`）、公证、Markdown 表格/图片（v1.1）、
图钉拖拽物理（v1.1）。

**大概率永远不做**——标签即文件夹、嵌套分类、任何要求你先归类的东西。
这个 App 奖励写，不奖励整理。

---

## 已知不足

坦白没做完的部分：

- **PP Editorial New 显示字体未内置**——标题回退系统衬线（该字体在字体厂
  官网被邮箱 gate 住，无法自动获取）。
- **暂无 demo 视频。**
- **搜索框聚焦环不显示**——nonactivating panel 里 SwiftUI focus/hover 的
  深层 quirk；已记录，影响很小。

---

## 路线图

- **已发布**——浅色主题、Live Markdown（含待办 + slash 菜单）、滑动操作、
  可自定义快捷键、自动化公开发布。
- **v1.1**——Markdown 图片与表格、图钉拖拽物理、搜索环修复、内置显示字体
  + demo、更多打磨。
- **v2**——深色主题（自己的 mood board → `/design-consultation`）、公证、
  Sparkle 自动更新，可能还有 iOS 端。

---

## 致谢

- **Kinfolk**——证明了 sage 可以是一个品牌。
- **Things 3 (Cultured Code)**——Mac 原生手感的标杆。
- **Linear**——单色设计系统并不无聊。
- **Bear**——live editing 模型：输入即上样式，无模式切换。
- **PP Editorial New**（Pangram Pangram）· **General Sans**（Indian Type
  Foundry）· **JetBrains Mono**——三款字体。
- **SideNotes**——我们想在设计上超越的那个开创品类的主力。

---

## 许可证

[MIT](LICENSE) © 2026 oliverxuzy。代码随你怎么用。

内置的第三方字体保留各自许可证，**不**在 MIT 覆盖范围内：General Sans
（Fontshare 免费许可）、JetBrains Mono（Apache-2.0）、PP Editorial New
（Pangram Pangram 条款，若添加）。详见
[`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md)。

---

<div align="center">

*由 [@oliverxuzy](https://github.com/oliverxuzy-ai) 耐心打造。*

</div>
