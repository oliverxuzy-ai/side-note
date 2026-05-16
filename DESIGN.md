# Design System — side-note

> Mac sidebar Markdown 笔记 App，设计驱动产品。
> 通过 office-hours (2026-05-14) + design-consultation (2026-05-14) 收敛。
> 北极星：**"从屏幕边缘滑出的那块 sage 让我肩膀松了一下"**——身体状态变化是品牌。

---

## Product Context

- **What this is**：Mac 上从屏幕边缘滑入/滑出的 Markdown 笔记侧边栏 App
- **Who it's for**：作者自己 + 同道 (Claude Code / vibe-coding / 写作 + 编码混合工作流的用户)
- **Space/industry**：Mac 生产力 / 个人笔记（与 SideNotes、Bear、Apple Notes 共生态位）
- **Project type**：macOS 14+ 原生 App，SwiftUI

## Aesthetic Direction

- **Direction**: **Modernist Calm with Sage Monochrome**
- **Decoration level**: minimal-intentional（字体 + 单一色相 + 精心调校材质承担全部表现力）
- **Mood**: 在场但不抢戏。一种"沿着你已有的注意力放下，而不是吸引它"的设计语气。
- **Reference 集合**：
  - Mood board: `~/.gstack/projects/side-note/mood-board-light.png`（8 张 Kinfolk-sphere 图像）
  - Things 3 sidebar UX（材质 + 留白）
  - Linear 暗模式（单色调监化系统）
  - Kinfolk 官网（sage 调性来源）

## Color

- **Approach**: sage monochrome — 一个色相（sage 绿）的多种浓度承担整个色彩系统。无暖色，无 semantic palette。Accent 稀有出现 = 出现时被身体记住。

### Light Theme（v1 已锁定）

```
═══ CANVAS — SwiftUI Material 3-layer composition (M1 第三次升级) ═══

Layer 1 (底)：SwiftUI `.regularMaterial`
              （macOS 12+ SwiftUI 原生玻璃材质，对应 Apple Notes / Finder 侧栏体感）
              用 `Rectangle().fill(.regularMaterial)`，**不**用 NSVisualEffectView

Layer 2 (中)：Color #C1C5B0 @ opacity 0.10   /* sage 染色层 */
              比 NSVisualEffectView 路线低（之前 0.12），因为 Material 自己就略偏暖

Layer 3 (上)：Color #FFFEFA @ opacity 0.20   /* 暖白 wash */
              比 NSVisualEffectView 路线大幅降低（之前 0.45），因为 Material 玻璃感强，
              过厚 wash 会盖死 vibrancy。20% 是"可读 + 仍能感受到桌面颜色"的平衡点

设计意图：参考 Apple Notes / Finder 侧栏的"半透明玻璃"语言。
不同桌面差异显著：暗壁纸 → App 偏深偏冷；浅壁纸 → 接近 sage 白；彩色壁纸 → 接受染色。
「肩膀松那一下」不来自静态颜色，来自一种"有内容透过来"的物质感。

═══ SURFACE (cards, lists, inputs — 玻璃之上的半透明白卡) ═══
surface            rgba(255, 255, 255, 0.55)   /* 半透明白卡片 */
surface-hover      rgba(255, 255, 255, 0.70)
surface-selected   rgba(255, 255, 255, 0.88)
（不用纯填色——卡片靠 hairline border + 极轻阴影区分层级。canvas 已是玻璃，
  填色会让卡片显得"碎"。半透明白卡 = 玻璃之上的"高亮区"，依然能让 vibrancy
  通过卡片底色微弱透出来，整体保持玻璃连续性。）

═══ BORDER ═══
border-hairline    rgba(31, 30, 24, 0.07)   /* 卡片边缘 */
border-faint       rgba(31, 30, 24, 0.04)   /* 分隔线 */

═══ TEXT ═══
text-primary       #1F1E18   /* 暖近黑，不是 #000 */
text-muted         #75726A   /* 元信息、次要文字 */
text-faint         #A8A59C   /* placeholder、时间戳 */

═══ ACCENT (sage at intensity, no warm color anywhere) ═══
accent             #6E8060   /* refined rosemary — 图钉/选中立柱/按钮/链接 */
accent-soft        #B8C2A8   /* hover、链接下划线 wash */
accent-deep        #4F5E45   /* active/pressed、链接文字 */
```

### Accent 使用规则（严格）

Accent 只出现在 **4 处**：
1. 置顶笔记的金属图钉（sage 渐变 ceramic 质感）
2. 选中卡片左侧 2pt 立柱
3. Markdown 链接文字
4. "New note" 按钮

其他地方一律**不用 accent**。这保证它一出现你的眼睛就被牵走 = 被身体记住。

### Dark Theme（v2 待 mood board，暂留 open question）

需要做 `dark.png` mood board 后决定：保持 sage monochrome 逻辑（深色版 = 深苔藓底 + 浅 sage accent），还是切换到 Bauhaus（黑 + 几何 + 单一冷强调）。**贴 mood board 时身体说了算。**

## Typography

### Stack

- **Display (laser-cut headlines)**: **PP Editorial New** (Pangram Pangram, 个人/商业免费)
  - 落地下载: https://pangrampangram.com/products/editorial-new
- **Body (UI + 正文 + 列表)**: **General Sans** (Indian Type Foundry / Fontshare, 免费)
  - 在线 CDN: `https://api.fontshare.com/v2/css?f[]=general-sans@400,500,600&display=swap`
- **Mono (code blocks, 行内代码)**: **JetBrains Mono** (免费)
- **Italic emphasis**: PP Editorial New Italic（编辑衬线斜体特别漂亮，是 v1 唯一的"装饰性"字形）

### Scale（Mac native 数值，pt 单位）

```
═══ DISPLAY (PP Editorial New) ═══
H1 笔记标题        28pt regular,  leading 1.15,  tracking 0
H2 章节            21pt regular,  leading 1.25,  tracking 0
H3 子章节          17pt medium,   leading 1.30,  tracking 0
Italic 强调        PP Editorial New Italic, 行内继承父级字号

═══ BODY (General Sans) ═══
正文               15pt regular,  leading 1.55
列表项 / 卡片摘要   13pt regular,  leading 1.45
按钮文字           13pt medium
时间戳 / 大写标签   11pt regular,  tracking 0.02em

═══ MONO (JetBrains Mono) ═══
代码块             13.5pt regular, leading 1.5
行内 code          13pt regular（匹配 body line-height 以免破坏行间距）
```

## Spacing

- **Base unit**: 4pt（Apple HIG 对齐）
- **Density**: comfortable（不 compact 不 spacious）

```
2xs(2)  xs(4)  sm(8)  md(12)  lg(20)  xl(28)  2xl(40)
```

应用规则：
- 卡片内 padding: 14pt 横 × 16pt 竖
- 卡片间距: 10pt
- 卡片到侧边: 16pt
- 标题到正文: 6pt
- 列表项到 meta: 10pt

## Layout

- **Approach**: grid-disciplined（单列笔记列表，阅读宽度内容）
- **侧边栏默认宽度**: 380pt（15pt body 在 ~52 字符行长，最舒服区间）
- **Min width**: 320pt（仍可读）
- **Max width**: 520pt（再宽行长破坏阅读）
- **Border radius**:
  - sm 6pt（标签、chip）
  - md 10pt（卡片、按钮、输入框）
  - lg 14pt（设置面板、Sheet、窗口本身）
- **窗口架构**: NSPanel + `.nonactivatingPanel` + `.canJoinAllSpaces` + `.fullScreenAuxiliary`（不用 NSWindow，避免抢应用焦点）

## Motion

唯一被刻意放大的设计层。其他动效一律克制，所有 motion 投资集中在滑入瞬间。

### Tokens (SwiftUI)

```swift
extension Animation {
  // 北极星动作：侧边栏滑入
  static let slideIn = Animation.interpolatingSpring(
    response: 0.32,
    dampingFraction: 0.78
  )
  // 滑出（更快、ease 不 spring，干净收走）
  static let slideOut = Animation.easeIn(duration: 0.22)
  // 按钮、图钉等微交互
  static let pressFeedback = Animation.interpolatingSpring(
    response: 0.18,
    dampingFraction: 0.86
  )
  // 通用 hover / 状态切换
  static let hover = Animation.easeOut(duration: 0.16)
}
```

### 滑入编排（the memorable beat，~380ms 总时长）

```
t=0ms       面板 off-screen，content alpha 0
t=0→260ms   面板 spring 进入，95% 位置时 overshoot 开始
t=80ms      content fade-in 启动（panel 已在路上一半时再开始）
            content 自带 12pt 向左 parallax → catch up 到最终位置
t=380ms     稳定
```

**12pt parallax 是关键**——把"一块东西从右边来"拆成"面板 + 内容两个分层"，眼睛感知到的是层次而不是位移。这就是肩膀松的物理基础。

### 滑出（快、干净）

```
t=0→100ms     content alpha 1 → 0
t=0→220ms     面板 easeIn 收走
```

### 其他 motion

- 卡片 hover: 120ms ease-out 背景过渡
- 图钉按下: spring-fast 缩放 0.96 → 1.0
- 选中切换: 120ms ease-out 左立柱 + 背景
- **不做**: 列表入场动效、skeleton shimmer、装饰性 motion、micro-interactions on every click

## 物质细节

### 置顶图钉（the brand element）

- 形状：12pt × 18pt 椭圆顶 + 细针下垂
- 渐变：`linear-gradient(160deg, #4F5E45 0%, #6E8060 45%, #B8C2A8 65%, #6E8060 100%)` — 模拟陶瓷高光
- 旋转 8° 顺时针（不正不歪，"被刚钉上"的物理感）
- 阴影：`0 2px 3px rgba(0,0,0,0.18), inset 0 1px 1px rgba(255,255,255,0.30)`
- 细针：`linear-gradient(180deg, #4F5E45 → #6E8060 → transparent)`，2pt 宽 16pt 高

### 卡片层级

由于 canvas 已是近白，卡片**不用填色区分**，靠：
- 1px hairline border (`rgba(31, 30, 24, 0.07)`)
- 1pt 轻阴影 (`0 1px 1px rgba(31, 30, 24, 0.04)`)
- 55% 半透明白底（vibrancy 微微透过）

选中卡片：
- 背景拉到 88% 不透明白
- 左侧 2pt accent 立柱（inset shadow）
- 阴影微强

## Markdown 渲染（v1 子集，8 类）

**Live inline editing（Bear 风格，无 view/edit 切换）**：单一始终可编辑的
NSTextView，输入即上样式。标记符（`#` `**` `` ` `` `>` `[]()`）**保留但变淡**
（text-faint），不隐藏——所见即所改，光标/选区/撤销不被打断。

实现用按行 + 行内正则即时上属性（只改属性不改字符），对半成品 markdown 鲁棒，
比 AST 重解析快。不再依赖 `swift-markdown`。

v1 支持：标题（H1-H3）/ 段落 / 无序列表 / 有序列表 / 行内 code / 代码块 / 引用块 / 粗体 & 斜体 / 链接。

v1.1 推迟：图片、表格、任务列表、脚注、删除线、嵌套引用、HTML 块。

未支持语法原样显示，不报错。

### 视觉规则

- **标题** = PP Editorial New，按上面的字号梯度
- **段落** = General Sans 15pt
- **链接** = `text-color: accent-deep (#4F5E45)`, `underline-color: accent-soft (#B8C2A8)`, `underline-offset: 2pt`
- **行内 code** = JetBrains Mono 13pt, 背景 `rgba(31,30,24, 0.05)`, padding 1pt × 5pt, radius 3pt
- **代码块** = JetBrains Mono 13.5pt, 背景 `rgba(31,30,24, 0.04)`, 自身有 1px border-hairline + 10pt padding + 8pt radius
- **引用块** = 左侧 2pt accent-soft 立柱 + 12pt 缩进 + 文字色 text-muted
- **粗体** = font-weight 600（General Sans Semibold）
- **斜体** = 切换到 PP Editorial New Italic（这是 v1 唯一的 cross-family fallthrough，特意为之）

## Distribution

- **v1**：自签名 + GitHub Releases（.dmg）
- **v1 不上 App Store**：CGEventTap 在 sandbox 内不可用，会阻断边缘悬停触发
- **v2**：Notarization（不要 sandbox，~1 周）+ Sparkle 自动更新

详见 office-hours design doc 的 Distribution Plan 节。

## Open Questions

带入 v1 实施阶段决定，不是现在的事：

1. **Dark theme 方向**：sage 同源延伸 vs Bauhaus 反差。`dark.png` mood board 完成后用身体感受。
2. **正文区宽度**：固定 480pt 还是自适应。等做出来用一周自己用感受。
3. **多笔记切换 UX**：单列列表 vs 双栏（列表 + 当前笔记）。v1 倾向单列，需做出来验证。
4. **置顶笔记数量软上限**：建议 5 条，超过 UI 是否提示，v1 不强制。
5. **快捷键冲突**：`⌃⇧Space` 在某些输入法下可能冲突，首启动检测引导用户改。

## Decisions Log

| 日期        | 决定                                                                | 理由                                                                                                |
|-------------|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| 2026-05-14  | Memorable thing 锁定：滑出 0.4 秒的身体状态变化                       | office-hours D1—D6 + design-consultation D1，所有设计决策为此服务                                  |
| 2026-05-14  | Canvas = #F1F2E9 (静态近白 sage-tinted)，vibrancy 实现              | design-consultation D4（用户拒绝 #CDD0BF 解释"显 low"），iteration 2 锁定                          |
| 2026-05-14  | Accent 切换 terracotta → sage monochrome (#6E8060 refined rosemary) | design-consultation D5（用户拒绝"土地红色高光"），iteration 3 锁定。系统变成单色调而非暖冷对照     |
| 2026-05-14  | 卡片层级靠 border + shadow 而非填色                                  | canvas 已是近白，填色无对比；改成 hairline border + 55% 半透明白 + 轻阴影                          |
| 2026-05-14  | Display 字体: PP Editorial New                                       | mood board 里 ISSUE 59 / Kinfolk logo 调性的直接落地，免费个人/商业，比 Tiempos / GT Sectra 经济  |
| 2026-05-14  | Body 字体: General Sans                                              | Fontshare 免费，与 PP Editorial New 同样独立字体厂感性，比 Inter 暖 + 人文                         |
| 2026-05-14  | 滑入: 320ms spring + 12pt content parallax 80ms 延迟                | 把面板和内容拆成两层，眼睛感知层次而非位移；spring response 0.32, damping 0.78                     |
| 2026-05-14  | M1 实测：canvas 从 92% 不透明叠层 → full glass (3-layer composition)  | 用户："没看到像 macOS 原生那样背景颜色会泛上来"。92% 让 vibrancy 几乎不可见，违背"有玻璃感"的初衷    |
| 2026-05-14  | M1 实测：放弃"NSPanel 滑窗口位置"，改为"NSPanel 固定 + SwiftUI 内部 slide" | 玻璃变明显后窗口移动每帧重算 vibrancy 卡感更刺眼；改成单一 SwiftUI spring 驱动单层 slide，无 NSAnimationContext |
| 2026-05-14  | 移除 SwiftUI `.shadow` 修饰符（暂时无阴影）                            | `.shadow` 把整个面板栅格化成位图算阴影，导致 NSVisualEffectView 的活体毛玻璃被冻成快照。阴影留到 M3 polish 用 CALayer 级别加回 |
| 2026-05-14  | NSVisualEffectView → SwiftUI `.regularMaterial`（macOS 12+ 原生 API） | 参考 Deck 开源项目的实现。NSVisualEffectView 通过 NSViewRepresentable 包装进 SwiftUI 时各种兼容性 bug（透明度、clipShape、shadow 都易出问题）；SwiftUI 原生 Material 是 ShapeStyle，无包装层，Apple 官方推荐 |
| 2026-05-16  | 用户实测后：view/edit 两态切换 → **Bear 风格 live inline 编辑**          | 用户："没有 live editing… 像 Bear 那样不需要切换"。模式切换打断书写心流，违背"肩膀松"。改为标记保留但变淡的即时上样式 |
| 2026-05-16  | `swift-markdown` AST 渲染层 → 按行+行内**正则即时高亮**，移除该依赖      | live 编辑要对半成品 markdown 鲁棒且不卡；只改属性不改字符 → 选区/撤销天然不断。AST 重解析在每次按键下过重，且渲染层删除后该依赖成孤儿 |
| 2026-05-16  | M3+ 微交互不达标 → 统一 PressableButtonStyle / hover 抬升 / 列表⇄详情 spring 转场 | 用户："动画效果都非常一般"。这是"设计即品牌"北极星本身。坚持 DESIGN.md：只投有意义状态变化，**不加** loading shimmer/spinner（本地 IO 瞬时） |
