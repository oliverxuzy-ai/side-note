# Implementation Plan — side-note v1

> 4 周个人项目节奏。从空目录到可下载 `.dmg`。
> 北极星：**滑出 0.4 秒的身体状态变化**。每一个里程碑都为它服务。

---

## Goal

3–4 周后产出一个 **能被下载的 `.dmg` 文件**，里面是一个 **作者自己每天用的 macOS App**，并能录一段 30 秒 demo 视频不脸红。

## Definition of "usable v1" (作者自己用的最低门槛)

以下全部为真 = 可用：

1. **可靠开关**：菜单栏图标点击 / `⌃⇧Space` 热键 / 屏幕右边缘悬停三种方式任一都能稳定唤出
2. **数据不丢**：写完笔记关掉 App 再开，笔记还在；Mac 崩溃重启后笔记还在
3. **Markdown 渲染**：v1 8 类语法都能正确显示，渲染符合 `DESIGN.md` 排版规则
4. **置顶有效**：pin 一条笔记，重启 App 后还在最上方
5. **搜索能用**：`⌘F` 搜标题 + tags，结果实时过滤
6. **自己日均触发 ≥ 8 次**（连续一周）

---

## Milestones

```
Week 0   Setup            (1–2 天)        →  能 build & run 一个空 SwiftUI 窗口
Week 1   Slide-in spike   (5–7 天)        →  北极星验证：身体确实在松
Week 2   Core read/write  (5–7 天)        →  能用：自己可以替代当前笔记习惯
Week 3   Visual polish    (5–7 天)        →  能拍：30 秒 demo 不脸红
Week 4   Ship             (3–5 天)        →  能下：.dmg 在 GitHub Releases
```

---

## Milestone 0 · Project setup (~1–2 天)

**Goal**：把脚手架立起来。

**DoD**：在 Xcode 里 `⌘R` 能跑出一个空白 macOS 窗口，window title 是 "side-note"。

### Tasks

- [ ] 装好 Xcode 15+ 和 Command Line Tools
- [ ] 在 repo 根目录 `mkdir SideNote && cd SideNote && xcodebuild ...` 或直接 Xcode → New Project → macOS → App，模板选 SwiftUI App，名字 `SideNote`，min deployment macOS 14.0
- [ ] `.gitignore` 加 Xcode/Swift 标准模板：`xcuserdata/`、`*.xcuserstate`、`build/`、`.swiftpm/`、`Pods/`、`DerivedData/`
- [ ] 安装下面三个依赖（Xcode → File → Add Package Dependencies）：
  - `https://github.com/apple/swift-markdown` (latest)
  - `https://github.com/soffes/HotKey` (latest)
  - 可选：`https://github.com/sindresorhus/Defaults` (NSUserDefaults 的更好包装)
- [ ] 设置 entitlements：禁用 sandbox（v1 不上 App Store，需要 CGEventTap），开 `com.apple.security.files.user-selected.read-write` 和 `com.apple.security.network.client = false`
- [ ] 创建项目骨架（文件夹结构见下）
- [ ] Git commit: "chore: scaffold SwiftUI app"

### 文件夹骨架（建议）

```
SideNote/
├── App/
│   ├── SideNoteApp.swift          # @main 入口
│   └── AppDelegate.swift          # 菜单栏 + 热键挂载
├── Features/
│   ├── Sidebar/                   # 主面板 SwiftUI
│   │   ├── SidebarPanel.swift
│   │   ├── NoteListView.swift
│   │   ├── NoteCard.swift
│   │   └── NoteDetailView.swift
│   ├── Editor/                    # Markdown 编辑/渲染
│   │   ├── MarkdownEditor.swift
│   │   └── MarkdownRenderer.swift
│   └── Settings/
│       └── PreferencesView.swift
├── Core/
│   ├── Storage/                   # 文件系统笔记 IO
│   │   ├── NoteStore.swift
│   │   ├── NoteFile.swift
│   │   └── FrontmatterCodec.swift
│   ├── Triggers/                  # 三种触发方式
│   │   ├── MenuBarController.swift
│   │   ├── HotkeyService.swift
│   │   └── EdgeHoverService.swift
│   └── Window/
│       ├── SlidePanel.swift       # NSPanel 子类
│       └── VisualEffectView.swift # NSVisualEffectView 包装
├── DesignSystem/
│   ├── Colors.swift               # DESIGN.md 的 token 翻成 Color
│   ├── Typography.swift           # PP Editorial New / General Sans 加载
│   ├── Spacing.swift
│   └── Motion.swift               # Animation 预设
├── Resources/
│   ├── Fonts/                     # PP Editorial New, General Sans
│   └── Assets.xcassets
└── SideNoteTests/
```

### Risk
- Xcode 项目放在 git 里管理一些 `.xcodeproj` 内部文件会有 noise。可考虑用 [Tuist](https://tuist.io) 或 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 从 yaml 生成 `.xcodeproj`，但 v1 不值得，直接 Xcode 默认。

---

## Milestone 1 · Slide-in spike ✅ COMPLETE

**Goal**：验证北极星。在面板里塞硬编码的 4 条假笔记，**滑入动画必须做对**。

**DoD**：

- 按 `⌃⇧Space` 后，一个 380×720 的面板从屏幕右边缘滑入，~380ms
- 内容有 12pt parallax 延迟（panel 先到，content 后到）
- canvas 颜色是 `#F1F2E9`，材质透过 NSVisualEffectView
- 再按一次热键 / 点菜单栏 icon / 把鼠标移开 → 面板滑出
- **录一段 5 秒视频自己看，是不是肩膀松了一下**——这是 GO / NO-GO gate

### 实际交付（vs 计划的偏离）

实际实施过程中根据真机体验做了几次架构调整。**北极星身体测试通过**（用户："卡顿解决了"+"玻璃可以"+"阴影对了"），M1 GO。

主要偏离：

| 原计划 | 实际 | 原因 |
|--------|------|------|
| NSPanel 用 NSAnimationContext 滑动位置 + SwiftUI 内容做 parallax | NSPanel 不动，单一 SwiftUI spring 驱动 surface offset | 两套时钟 + 系统每帧重算 vibrancy/shadow = 卡 |
| NSVisualEffectView 包装为 NSViewRepresentable 做 vibrancy | SwiftUI 原生 `.regularMaterial` (`Rectangle().fill(.regularMaterial)`) | NSViewRepresentable 包装层和 `.shadow`/`.clipShape` 各种兼容性 bug，参考 yuzeguitarist/Deck 改用 Apple 推荐方式 |
| canvas 92% 不透明 + vibrancy 微微呼吸 | full glass 三层合成（`.regularMaterial` + sage tint 10% + 暖白 wash 20%） | 用户："没看到像 macOS 原生那样背景颜色会泛上来" |
| NSPanel.hasShadow = true 矩形系统阴影 | SwiftUI 三层堆叠 shadow (contact/mid/ambient) + panel 四向 shadowMargin 45pt | 单层 shadow 边界硬，参考 Material Design elevation 改三层模拟自然光照 |
| terracotta accent 暖色 | sage monochrome 系统 | 用户："不喜欢这个土地红色的高光"（也已在 DESIGN.md 锁定） |

### M1 推迟到 M3 polish 的项

代码里已留 TODO / 注释指明：

- **边缘悬停触发**（CGEventTap + Accessibility 权限引导）—— 当前只有菜单栏点击 + ⌃⇧Space
- **真 PP Editorial New 字体加载**—— 当前用系统衬线 `New York`
- **点击 surface 外区域 dismiss**—— 当前只能再按热键或菜单栏关
- **置顶 pin 拖动物理弹回**—— 当前只有静态 ceramic 图钉
- **shadow 进一步调参**—— 用户当前接受度："好多了，先收尾吧，到时候再改"

### Tasks

- [ ] `SlidePanel.swift`：继承 NSPanel，`styleMask: [.borderless, .nonactivatingPanel]`，`level: .floating`，`collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]`
- [ ] `VisualEffectView.swift`：NSViewRepresentable 包装 NSVisualEffectView (`.contentBackground`, `.behindWindow`)，叠 92% canvas 色
- [ ] 滑入动画用 SwiftUI `.transition` + `interpolatingSpring(response: 0.32, dampingFraction: 0.78)`
- [ ] 12pt content parallax: content 用单独的 `.offset(x:)` + 80ms 延迟 + 自己的 spring
- [ ] 滑出: `easeIn(duration: 0.22)` 面板 + `easeIn(duration: 0.10)` content 透明
- [ ] `HotkeyService.swift`: 用 `soffes/HotKey` 注册 `⌃⇧Space`，回调 toggle 面板
- [ ] `MenuBarController.swift`: NSStatusItem，单击 toggle 面板
- [ ] 硬编码 3 条假笔记在面板里展示（用 SwiftUI 直接写死，不接 storage）
- [ ] 录视频自测

### Risk + 应对

| 风险                                                  | 应对                                                                                          |
|------------------------------------------------------|----------------------------------------------------------------------------------------------|
| NSPanel + SwiftUI transition 配合有 hack              | 用 `NSAnimationContext` 包 NSPanel frame 动画，content 用 SwiftUI transition；分两层各动各的     |
| 边缘悬停需要 Accessibility 权限                       | Week 1 先不做边缘悬停，只做热键 + 菜单栏。边缘悬停推到 Week 2 末或 Week 3                       |
| 滑入感觉不对                                          | 调参数（spring response 0.28 / 0.36 都试一下；parallax 8pt / 16pt 都试）；最差情况退回到 v0.1   |
| **真的肩膀没松**                                      | **STOP。回到 `/office-hours` 重新审视北极星。这是这个项目最大的赌注**                          |

---

## Milestone 2 · Core read/write loop ✅ COMPLETE

**Goal**：能用。自己开始替代当前的笔记习惯。

**DoD**：v1 in scope 的功能除 visual polish 外全部跑通。每天用 ≥ 8 次。

### 实际交付（vs 计划的偏离）

storage / markdown / editor / 列表-详情导航 / 搜索 / 快捷键 / 外部变更冲突条全部落地。
14 个单测全绿（codec corner case + ULID + markdown 子集 + NoteStore 磁盘往返集成）。
「数据不丢」DoD 通过 NoteStore 集成测试端到端验证（写盘 → 全新 store 重扫 → 内容仍在）。

| 原计划 | 实际 | 原因 |
|--------|------|------|
| `Yams` 包解析 YAML frontmatter | 手写 `FrontmatterCodec`（标题强制加引号 + 容错解码） | frontmatter 只 6 个扁平字段、格式自写自读，引工业级 YAML 库是过度依赖。corner case（含`:`/emoji 标题、空/缺失/损坏 frontmatter）用单测覆盖 |
| 文件名隐含跟随 title | 文件名 = `<ULID>.md`，标题只活在 frontmatter | title 改一次就 rename 文件 → rename 触发 FSEvents → 回环风险。ULID 当名 = 稳定，且字典序==时间序，目录排序即创建序 |
| FSEvents 用 `DispatchSource` vnode 监听 | `FSEventStream` + `kFSEventStreamCreateFlagFileEvents` | vnode 只报目录条目增删，**不报文件内容修改**；而「外部编辑器改了当前笔记要提示」必须感知内容修改 |
| 删除 = `trashItem` | trash 优先，失败回退 `removeItem` | 某些卷（网络盘 / 临时卷）不支持 Trash，`try?` 会静默吞掉导致「删了还在」。回退硬删除保证语义 |
| 编辑器语法高亮（H1 加粗 / code 等宽）| M2 = 纯文本编辑器 | 高亮 / live preview 是观感而非「能用」，风险大收益低，推 M3 polish |
| 冲突条含 `[查看 diff]` | M2 = `[保留磁盘版] [保留本地]` 两个动作 | diff UI 重；两个动作已覆盖「不丢数据」核心。diff 推 M3 |
| 真 PP Editorial New / General Sans / JetBrains Mono | `Typography.swift` 用系统回退（serif/sans/mono），字号行距严格照 DESIGN.md | 字体文件加载是 M3 任务。M3 只改 Typography 里三个 family 函数，调用点不动 |

### M2 已知项 / 推迟到 M3

- **首启动 macOS 会弹一次「允许 side-note 访问 Documents 文件夹」系统框**——`~/Documents/SideNote` 受 TCC 保护，点一次 Allow 即可（真实用户一次性行为；自动化测试用临时目录绕开验证逻辑）
- 编辑器语法高亮 + live preview（M2 是 toggle 两态）
- 冲突条 `[查看 diff]`
- 真自定义字体加载（M3 Typography 任务）
- ⌘ 快捷键依赖 panel 为 key window（open() 已改 `makeKeyAndOrderFront`）；边缘悬停触发仍在 M3

### Tasks

#### Storage

- [ ] `NoteFile.swift`: struct 表示一条笔记（id: ULID, title, body, pinned, tags, created, updated）
- [ ] `FrontmatterCodec.swift`: 用 `Yams` 包做 YAML frontmatter 解析（依赖加上）
- [ ] `NoteStore.swift`: 监听 `~/Documents/SideNote/` 目录的 `.md` 文件
  - 启动时扫描所有 `.md` → 数组
  - 用 FSEvents (`DispatchSource.makeFileSystemObjectSource`) 监听变化
  - 写 = 原子写入（先写到 `.tmp` 文件再 rename，避免半写状态）
  - CRUD: `new()` / `save(_:)` / `delete(_:)` / `togglePin(_:)`
- [ ] 删除 = `FileManager.default.trashItem(...)`（送 Trash，不真删）

#### Markdown

- [ ] `MarkdownRenderer.swift`: 拿 `swift-markdown` 的 `Document` AST → 自写 SwiftUI render
  - v1 子集 8 类: H1-H3, paragraph, ul, ol, inline code, code block, blockquote, bold/italic, link
  - 不支持的语法（image, table, task list）**原样显示文本**，不报错
  - 渲染规则严格照 `DESIGN.md` 走

#### Editor

- [ ] `MarkdownEditor.swift`: 一个 NSTextView (NSViewRepresentable) 包装
  - 编辑时显示纯文本 + 语法高亮（H1 加粗、code 等宽）
  - 失焦或 `⌘S` 保存（实际上是 debounce 自动保存）
  - 切换到"查看模式"时显示渲染后的 SwiftUI 视图（v1.1 再做 "live preview"，先做 toggle）

#### UI

- [ ] `NoteListView.swift`: 笔记列表，pinned 优先 + updated 倒序
- [ ] `NoteCard.swift`: 一条卡片，DESIGN.md 规格
- [ ] `NoteDetailView.swift`: 选中后展示笔记内容（点击切到 detail）
- [ ] 基础操作快捷键: `⌘N` 新建 / `⌘⌫` 删除 / `⌘F` 搜索 / `⌘P` toggle pin
- [ ] 搜索 UI: 顶部搜索框（DESIGN.md 已规范）模糊匹配标题 + tags
- [ ] 外部修改冲突提示: FSEvents 检测到当前编辑文件被外部改 → 顶部条 "外部已变更 [查看 diff] [覆盖本地] [保留本地]"（DESIGN.md 规范）

### Risk + 应对

| 风险                                              | 应对                                                                  |
|---------------------------------------------------|-----------------------------------------------------------------------|
| 自写 Markdown 渲染层耗时 > 2 周                   | 退路：v1 用 `MarkdownUI` 第三方包，v1.1 替换为自写；接受 visual 80% 准 |
| YAML frontmatter 解析在 corner case 上挂          | `Yams` 是工业级，但要测：emoji 标题、含 `:` 的标题、空 frontmatter      |
| 编辑器和渲染同步状态混乱                          | v1 用 "编辑 / 查看" 两个明确模式，不做 live preview                     |

---

## Milestone 3 · Visual polish ✅ COMPLETE（code 部分）/ ⏳ 待用户（字体 + demo）

**Goal**：能拍 30 秒 demo 视频不脸红。

**DoD**：

- DESIGN.md 里所有视觉规则都落地
- 录 30 秒视频展示 滑入 → 切换笔记 → 创建笔记 → 置顶 → 滑出
- 视频自己看一遍 + 第二天再看一遍，都不觉得"哪里不对"

### 实际交付（vs 计划的偏离）

字体加载链路 / Markdown 排版规则 / 微动效 / 边缘悬停触发 + Preferences + AX 权限引导
全部落地。build + 14 单测全绿，App 启动无崩溃。

| 原计划 | 实际 | 原因 |
|--------|------|------|
| 三种字体都打包 | JetBrains Mono(v2.304 GitHub) + General Sans(Fontshare) 已打包 + 运行时注册验证 OK；**PP Editorial New 未打包** | PP Editorial New 在 pangrampangram.com 邮箱/点击 gate 交付，无静态 URL，不绕 gate。display/标题优雅回退系统衬线 New York，等用户补（见下「待用户」） |
| Info.plist `ATSApplicationFontsPath` 注册字体 | 运行时 `CTFontManagerRegisterFontsForURL(.process)` 递归扫 bundle | xcodegen 把资源平铺进 Resources/，子目录不保证保留，相对路径会落空；运行时扫描不依赖打包布局，确定 |
| 颜色 token 从 Asset Catalog 读 | 沿用 M1 的 `DesignTokens.swift` 单一出处 | 已集中、已锁定，再加 Asset Catalog 是重复源，违背单一真相 |
| 链接 `underline-offset: 2pt` | 文字 accent-deep + 下划线 accent-soft（`Text.LineStyle(color:)`）；offset 2pt 未做 | 纯 SwiftUI `Text` 无法控制 underline offset。颜色已对，offset 是次要观感，推 v1.1 |
| 行内 code 背景 padding 1×5pt + radius 3pt | 背景色对（rgba 0.05），padding/radius 未做 | SwiftUI `Text(AttributedString)` 无法给单个 run 加 padding/圆角。代码块（块级）规格完整 |
| 粗体 `base.weight(.semibold)` | `Typography.bold()` 显式选 GeneralSans-Semibold | 自定义字体不响应 `.weight()` 合成，必须按 PostScript 名选对应字重文件 |
| 边缘悬停 CGEventTap | CGEventTap `.listenOnly` mouseMoved + AXIsProcessTrusted + Preferences opt-in（默认关，UserDefaults `edgeHoverEnabled`） | 按 PLAN/DESIGN：默认关、主动开启才请求权限；拒绝也不崩，⌃⇧Space + 菜单栏照常 |

### ⏳ 待用户（两项我无法代劳）

1. **补 PP Editorial New 字体**（30 秒）：
   - 去 https://pangrampangram.com/products/editorial-new → "Free / Try for Free" 下载
   - 把 **PPEditorialNew-Regular.otf** 和 **PPEditorialNew-Italic.otf**（或 .ttf）丢进
     `SideNote/Resources/Fonts/`
   - 代码已按 PostScript 名 `PPEditorialNew-Regular` / `PPEditorialNew-Italic` 自动识别，
     重新 build 即生效，**无需改任何代码**；文件名/字重不同时告诉我我来对接
   - 没补也能用：标题/H1-H3/斜体回退系统衬线，不崩
2. **录 30 秒 demo 视频**（QuickTime 屏幕录制）+ 隔天再看一遍 —— 这是 M3 的 GO 信号，只能你来。

### Tasks

- [ ] **Typography**：加载 PP Editorial New + General Sans + JetBrains Mono 字体
  - 把 `.otf` 文件放到 `Resources/Fonts/`
  - `Info.plist` 注册 `ATSApplicationFontsPath`
  - 写 `Typography.swift` 暴露 `Font.display(size:)` / `Font.body(size:)` 等
- [ ] **颜色 token 落地**: `Colors.swift` 暴露 `Color.canvas`, `Color.accent` 等，从 Asset Catalog 读
- [ ] **置顶图钉**: 用 SwiftUI Shape 画 ceramic 图钉（DESIGN.md 规格：12×18pt，linear gradient，rotate 8°，shadow + inset highlight）
- [ ] **选中态**: 卡片左 2pt accent 立柱（inset shadow）、背景拉到 88% 不透明白
- [ ] **链接样式**: `text-color: accent-deep`, `underline-color: accent-soft`, offset 2pt
- [ ] **代码块**: JetBrains Mono 13.5pt + 背景 `rgba(31,30,24, 0.04)` + 1px hairline border
- [ ] **微动效**: 卡片 hover 120ms ease-out、图钉 press spring-fast 0.96→1.0、选中切换 120ms ease-out
- [ ] **边缘悬停触发**（推到这里因为需要 Accessibility 权限引导 UX）:
  - `EdgeHoverService.swift`: CGEventTap 监听全局鼠标位置
  - 首启动 Preferences 默认关闭，开关时 `AXIsProcessTrustedWithOptions` 请求权限
  - 引导文案 + 深链到 System Settings → Privacy & Security → Accessibility
- [ ] **录 demo 视频**（用 QuickTime 屏幕录制）

### Risk

| 风险                                                       | 应对                                                          |
|------------------------------------------------------------|---------------------------------------------------------------|
| 自定义字体在 SwiftUI 里嵌入有 corner case                  | Apple 文档：`Info.plist` + `Resources/Fonts/` + `.font(.custom(_:size:))`；测试 |
| ceramic 图钉用纯 SwiftUI Shape 画不出来                    | 退路：用 SF Symbols 的 `pin.fill` + tint + rotation，简化为图标层 |
| 边缘悬停首启动 UX 卡住                                     | 引导文案做到极简：3 步图示，1 张截图；被拒绝走降级 fallback     |

---

## Milestone 4 · Ship ✅ 流水线就绪 / ⏳ 待确认发布

**Goal**：能下载。`.dmg` 挂在 GitHub Releases，朋友能拖进 Applications 直接用。

**DoD**：

- 你把 GitHub Releases 链接发给一个 mac 朋友，他能：① 下载 ② 双击 mount ③ 拖 .app 到 Applications ④ 右键打开 ⑤ 用起来
- README 加截图 + demo gif/视频

### 实际交付（vs 计划的偏离）

`.dmg` 全链路本地验证通过：Release archive（adhoc 签名，路线 A）→ 导出 .app →
create-dmg 打包 → 挂载 → 拖装布局 → 拷出到干净路径启动正常。1.9M。

| 原计划 | 实际 | 原因 |
|--------|------|------|
| Xcode → Archive 手动导出 | `xcodebuild -configuration Release archive` + 从 .xcarchive Products 取 .app | route A 不签 / 无 team，`-exportArchive` 对签名挑剔；从 archive 直接取 adhoc .app 最稳，且可命令行复现 |
| 路线 A/B 决策 | 路线 A（adhoc "Sign to Run Locally" + 右键打开） | PLAN 已推荐 A；project.yml 早已 `CODE_SIGN_IDENTITY: "-"` |
| （计划未提 app 图标） | 用锁定 sage 体系生成**占位图标**（squircle + 右侧滑入面板 motif + 一条 sageDeep 置顶线） | 无图标的 .app 发给朋友显得没做完。占位图标只用 DESIGN.md 已锁的 sage，可随时替换；不是新品牌方向 |
| 装饰 .dmg 背景图 | create-dmg 默认样式 | PLAN Risk 已写：v1 默认样式够干净，装饰图推 v1.1 |

### ⏳ 待用户（发布前的 owner-only）

1. **确认是否现在公开发布**：发 GitHub Release 是公开、难撤销操作，未经确认不发；可选先发 **draft release**（仅协作者可见、可删）让你过目
2. **截图 + 30 秒 demo**（M3 遗留，DoD 要求）：README/release notes 的视觉素材，只能你来
3. **（建议但不强制）补 PP Editorial New 字体再发**：现在标题是系统衬线回退，发出去等于 v1 没兑现"设计即品牌"北极星。补字体重 build 即可，无需改码

### Tasks

#### 签名

- [ ] 决定路线：A) 不签 + Gatekeeper 警告 + 用户右键打开 (免费) OR B) 买 $0/年 Apple Developer 账户做 Developer ID 签名
- [ ] **推荐 A**（v1 接受首启动右键打开，README 写清楚）；v2 再上 B + Notarization
- [ ] 如果 A：Xcode 里 Signing & Capabilities 选 "Sign to Run Locally"

#### 打包

- [ ] Xcode → Product → Archive → 导出 .app
- [ ] 用 [`create-dmg`](https://github.com/sindresorhus/create-dmg)（最简单的 .dmg 制作工具）：
  ```bash
  brew install create-dmg
  create-dmg \
    --volname "side-note" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "SideNote.app" 175 200 \
    --hide-extension "SideNote.app" \
    --app-drop-link 425 200 \
    "side-note-0.1.0.dmg" \
    "SideNote.app"
  ```
- [ ] 装饰 .dmg 背景图（可选，但 demo 视频会用到）：放一张设计过的 PNG 在 `.dmg` 挂载视图里

#### 发布

- [ ] GitHub Releases → New Release → tag `v0.1.0`
- [ ] 上传 `side-note-0.1.0.dmg`
- [ ] Release notes：1 段 "Why I built this" + 截图 + demo 链接 + "右键打开" 引导
- [ ] README 加：
  - Hero 截图（侧边栏滑出的样子）
  - 30 秒 demo 视频或 gif
  - Download 链接
  - 首启动 Gatekeeper 引导（"右键 → Open"）

#### CI/CD（v1 可跳过）

- [ ] **v1 手动构建发布**（每次 ~5 分钟，OK）
- [ ] v2 再上 GitHub Actions: tag 触发 → `xcodebuild archive` → `create-dmg` → 自动 upload release

### Risk

| 风险                                                | 应对                                                       |
|-----------------------------------------------------|------------------------------------------------------------|
| 首启动 Gatekeeper 把朋友劝退                        | README 第一行做引导；动图演示右键 → Open；接受少量摩擦      |
| `.dmg` 装饰背景图调起来花时间                       | v1 用 `create-dmg` 默认样式（也够干净）；装饰图推到 v1.1   |
| 朋友的 Mac 不是 macOS 14+                           | README 写明 min macOS 14.0；Gatekeeper 会直接拒绝旧系统     |

---

## 进度跟踪建议

- 每个 milestone 结束写一段 200 字的"实际 vs 计划"小结，提交到 `~/.gstack/projects/side-note/retro-week-N.md`
- 跑 `/retro` 让 gstack 帮你看进度模式
- 卡住超过 1 天的事项 → 跑 `/investigate` 看是不是钻牛角尖了
- 写完 Week 1 跑 `/plan-eng-review` 审你的代码架构（NSPanel + SwiftUI transition、CGEventTap、自写 Markdown 渲染都是技术坑，外部审一遍很值）

---

## 分发格式速查（你的问题答案）

| 格式      | 用途                          | 你需要吗？                                                                 |
|-----------|------------------------------|----------------------------------------------------------------------------|
| **`.app`** | Mac 应用本体（一个 bundle 文件夹）| Xcode 构建出来的就是它。运行时操作系统认这个。                              |
| **`.dmg`** ✅ | 分发用的"虚拟磁盘"，里面装一个 `.app` | **v1 用这个**。用户双击挂载、拖进 Applications。Mac 公开分发的标准。       |
| `.zip`    | 简易分发：直接打 `.app` 成 zip   | 能用但不专业；解压后用户还要手动拖到 Applications，少一步引导               |
| `.pkg`    | 安装器（适合复杂安装：多文件、需要后台脚本等） | 不需要。side-note 是单 .app，没安装步骤                                  |

**v1 路径**：Xcode → Archive → 导出 `.app` → `create-dmg` 包成 `.dmg` → GitHub Releases 上传 → 链接发出去。**单人路径全程 ~5 分钟手工劳动**。

---

## 下一步建议

1. **现在就做**：跑 Milestone 0（脚手架），1-2 天能完成
2. **Milestone 1 开始前**：跑一次 `/plan-eng-review` 审 NSPanel + SwiftUI transition + parallax 这一坨技术决策
3. **Milestone 1 录完 demo 视频后**：你身体的反应是 GO / NO-GO gate。这是这个项目最重要的 checkpoint，不要跳过

**记住 milestone 1 的 GO/NO-GO**：如果北极星没兑现（滑入没有让肩膀松），整个项目假设就动摇了。那时候应该 `/office-hours` 重新审一遍，而不是硬着头皮往后做。
