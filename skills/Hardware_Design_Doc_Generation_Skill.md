# Hardware Architecture Dashboard Generation Skill (Native EDA Style)

本文档总结了将传统硬件详细设计文档（Markdown/Word）转化为**“现代化、交互式、极客风 Web Dashboard”**的核心技能（Skill）与最佳实践。在未来的硬件设计文档开发中，应严格遵循本套体系进行构建。

## 1. 核心设计理念 (Core Philosophy)
*   **摒弃静态文档**：不再使用干瘪的 Markdown 或 PDF，而是构建拥有左侧全局导航（Sidebar）和右侧内容区（Content Pane）的单页面 Web 应用（SPA）。
*   **极致的极客美学**：采用类似顶级开发者文档（如 Stripe, Tailwind）的视觉规范。深色顶栏、玻璃拟态（Glassmorphism）吸顶导航、高对比度语法高亮。
*   **原生 EDA 级图表**：不依赖外部低清图片，全量使用原生 SVG、HTML/CSS 渲染的 Gantt 图以及调优后的 Mermaid 图表，确保在 4K 屏幕下依然无限放大不失真。

## 2. UI 框架与排版规范 (UI & Layout Guidelines)
*   **字体栈 (Typography)**：正文优先使用系统级无衬线字体（如 `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto`），代码和图表标识严格使用等宽字体（`'Roboto Mono', monospace` 或 `Consolas`）。
*   **色彩系统 (Color Palette)**：
    *   主色调采用深邃的科技蓝/极客黑（如 `#0f172a`, `#1e293b`）。
    *   文字使用板岩灰（`#334155` 用于标题，`#475569` 用于正文）。
    *   突出警示信息采用高饱和度色彩（如红色警示框 `#fef2f2` 背景 + `#ef4444` 左边框）。
*   **交互细节**：表格增加 Hover 斑马线效果，侧边栏导航点击高亮并支持平滑滚动（`scroll-behavior: smooth`）。

## 3. 高级硬件图表可视化 (Advanced Hardware Visualizations)

这是本套 Skill 的核心灵魂，必须摒弃传统的粗糙表达方式：

### 3.1 物理流水线拓扑图 (Custom SVG Datapath)
*   **布局策略**：对于芯片内部的物理数据流，采用原生 SVG 绘制 **“Z字型” (S-shape)** 或折返式流水线拓扑，模拟真实的物理走线，极大地节省横向空间。
*   **尺寸与防压缩策略 (Critical)**：
    *   画布宽度必须足够大（如 `1400px`），模块文字字号至少 **20px**，连线位宽标识至少 **14px**。
    *   **致命陷阱规避**：浏览器会自动压缩超大 SVG。必须在 CSS 中为 SVG 注入强硬规则：`min-width: 1400px !important; max-width: none !important; height: auto !important;`。
    *   外层包裹 `div` 必须设置 `overflow-x: auto`，并且对齐方式**必须使用 `justify-content: flex-start;`**，绝对不能用 `center`，否则超出的左侧内容会被永久裁切！

### 3.2 周期级时序图 (Native HTML/CSS Gantt)
*   **痛点**：传统 Markdown 表格无法直观表达硬件的 Clock Cycle 时序。
*   **解决方案**：使用 `div` 栅格拼接出来的原生甘特图（Gantt Chart）。
*   **结构**：左侧固定表头（信号名/模块名），右侧为横向可滚动的周期网格。通过精准计算 `width` 和 `left` 偏移量来绘制彩色 Block，完美表达硬件加法器复用、流水线 Bubble、握手等待等精细时序。

### 3.3 模块层级与状态机 (Mermaid.js)
*   使用 Mermaid 绘制模块架构树，但默认样式极度紧凑。
*   **强制调优**：
    *   在图表开头必须注入配置项：`%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 80, 'rankSpacing': 150, 'curve': 'bumpX'}}}%%`。拉大间距并使用平滑贝塞尔曲线。
    *   同样应用 SVG 防压缩规则，设置 `min-width: 1200px !important` 和外层容器的 `justify-content: flex-start`，确保图表庞大且舒展。

## 4. 硬件代码与高亮 (RTL Code & Syntax Highlighting)
*   **引擎**：集成 `highlight.js`，并必须显式加载 `verilog.min.js` 语言包。
*   **生命周期**：确保 HTML 中的 JS 加载顺序：`核心包 -> verilog语言包 -> hljs.highlightAll()`。HTML 标签必须使用 `<code class="language-verilog">`（注意不是 systemverilog，引擎只认 verilog）。
*   **主题覆写 (Theme Override)**：
    *   采用 `Atom One Dark` 等深色极客主题。
    *   **注释高亮补丁**：默认的暗灰色注释在深色背景下可视性极差。必须在全局 CSS 注入补丁：`.hljs-comment { color: #86efac !important; font-style: italic; }`，将注释改为亮浅绿色斜体，大幅提升阅读体验。

## 5. 自动化构建工具流 (Python Parser Workflow)
*   文档由 Python 脚本自动将散落的资料组合、解析并生成最终的 HTML。
*   **正则表达式与锚点**：脚本需具备自动扫描全文标题、生成侧边栏锚点并注入 HTML 对应 `id` 的能力。
*   **特殊块拦截**：脚本应当能够识别特定的标记（如 `[GANTT_START]`、`[SVG_DATAPATH_START]`），并在这些位置注入高阶可视化组件的代码。

---
**使用说明**：未来让 AI 协助撰写新的芯片模块详细设计说明书时，可直接将此文档内容喂给 AI，并下达指令：“*请按照《Hardware Architecture Dashboard Generation Skill》的标准，为我解析并生成新模块的设计文档。*”
