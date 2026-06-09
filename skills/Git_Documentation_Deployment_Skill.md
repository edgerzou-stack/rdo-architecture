# 现代硬件文档云端部署与纯净化工程技能 (Web Hardware Doc Deployment Skill)

在现代硬件研发（EDA/架构设计）中，我们往往拥有庞大杂乱的原始资产：`.docx` 详细设计、`.xlsx` 时序表、`.py` 转换脚本以及各种暂存 markdown。但当我们需要向外部团队或者架构委员会展示时，他们只需要看**最终的 Web 网页版文档**。

为了兼顾“本地随时研发”与“云端极致整洁”，总结出以下 GitHub Pages 纯净化文档部署技能：

## 1. Git 索引剥离法则 (The Git Index Decoupling)

**问题场景**：本地包含大量代码、脚本和原始文档（`.docx`, `.xlsx`）。如果直接 `git push`，云端仓库会变成一个大杂烩，阅读者点开首页面对一堆工程文件会感到迷茫。

**Skill 解决方案：`git rm --cached`**
不要物理删除任何文件，而是从 Git 的“追踪大脑”中把它们剔除出去。
```bash
# 1. 把所有文件从 Git 追踪树中移除（本地文件保留）
git rm --cached -r .

# 2. 重新精准捕获需要的网页资产
git add "**/*.html" "**/assets/*"

# 3. 提交净化后的快照
git commit -m "chore: only track html assets for clean web distribution"
```
这种做法的精妙之处在于：**你的本地电脑依然是你全副武装的开发环境，但 GitHub 上的仓库已经蜕变成了一个纯粹、干净的文档托管服务器。**

## 2. 强力白名单屏蔽 (The Whitelist Gitignore)

**问题场景**：剥离追踪后，下次运行 `git status` 时，Git 会把刚才剥离的 Excel 和 Word 标记为红色的 `Untracked files`，不仅非常碍眼，而且很容易在下次 `git add .` 时被不小心加回去。

**Skill 解决方案：默认拒绝，按需放行**
不要去 `.gitignore` 里一个个写 `*.xlsx`, `*.docx`, `*.py`。采用最高维度的安全策略——**“先全部屏蔽，再开白名单”**。

在根目录建立 `.gitignore`：
```gitignore
# 1. 屏蔽一切文件
*

# 2. 但放行所有的文件夹（为了能进入子目录找白名单文件）
!*/

# 3. 核心白名单：只追踪 HTML（和 README）
!*.html
!README.md
!.gitignore
```
这个法则极其强悍。无论你未来在本地新增了什么脚本、画了什么暂存草图，只要后缀不是 HTML，Git 都会彻底无视它，永远保持远端 Pages 仓库的绝对纯净。

## 3. GitHub Pages 入口收敛 (Centralized Navigation)

**问题场景**：虽然仓库里只有 HTML 了，但在面对多个模块（如 RDO Transform, RDO Resi Buffer）的文档时，团队成员在 GitHub 页面翻找层级仍然体验不佳。

**Skill 解决方案：README 强引导页**
由于 GitHub 默认在仓库首页展示 README，你需要将其打造为一个 **“中央导航站”**，不要写开发逻辑，只放 Pages 链接：

```markdown
# [Project Name] Architecture Dashboard

## 📖 Live Document Links (GitHub Pages)
直接点击下方链接访问云端实时架构文档：

### 🌟 [Top-Level Architecture Dashboard](https://<username>.github.io/<repo>/)
- 全局流水线与架构概览

### 🔬 [Sub-module Detailed Design](https://<username>.github.io/<repo>/sub_folder/doc.html)
- 详细时序图与参数矩阵
```
这样一来，别人拿到你的 GitHub Repo 地址时，第一眼看到的不是枯燥的文件树，而是直达各类精美排版文档的绿色传送门。

## 总结
这份部署流，彻底斩断了“工程产出环境”与“最终用户阅读环境”的耦合。以后所有的文档库都可以遵从这一标准套路：**本地狂野开发 -> 脚本一键生成 HTML -> 白名单过滤提交 -> README 导航引流**，这不仅体现了极客的代码洁癖，也极大降低了团队内部的沟通与阅览成本。
