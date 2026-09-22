# INIT — 项目初始化手册（供 AI 执行）

> 本文件是模板初始化的操作手册。AI 与用户逐项确认后，按步骤完成替换和定制，最后删除本文件。

## Step 0 · 前置检查

- [ ] 确认当前目录是复制自 `project_template` 的新项目目录（而不是模板本体）。
- [ ] `AGENTS.md` 顶部应有 TEMPLATE NOTICE 注释；若无，说明已初始化过，停止并询问用户。

复制模板推荐：`rsync -a --exclude '.git' --exclude '.DS_Store' <模板>/ <新项目>/`（`-a` 保留属性，排除模板自身的 git 历史）。

## Step 1 · 收集信息（向用户询问，逐项确认）

| # | 问题 | 用途 |
|---|------|------|
| 1 | 项目名？ | `{{PROJECT_NAME}}`：AGENTS.md 标题、mutagen 会话前缀。通常即目录名，与用户确认即可 |
| 2 | 服务器与仓库基目录（`host:/dir`，如 `tt:/workdir`）？ | `{{REMOTE_BASE}}`：`code/` 下所有仓库同步到 `{{REMOTE_BASE}}/<repo>`，无需逐仓库问路径 |
| 3 | 项目目标（2-5 句：做什么、为什么、关键手段）？ | `{{PROJECT_GOAL}}`：AGENTS.md Project Goal 段 |
| 4 | 实验形态？（GPU 训练 / 推理服务 / 数据处理 / 其他） | 定制 AGENTS.md "实验流程"措辞、Hard Rules 分级的适用范围、devlog 指标举例 |
| 5 | 是否保留 mutagen 同步机制？ | 默认保留；纯本地项目删除 `.mutagen/` 及 AGENTS.md 相关章节 |
| 6 | `code/` 首个仓库是否已知？ | 已知（如克隆某开源仓库/PR 作基线）→ Step 2 顺带登记 target；未知 → `ALL_TARGETS` 留空，之后按"附录 A"流程新增 |
| 7 | 需要哪些参考代码（baseline/对比系统）？ | 按需克隆进 `ref_code/`（流程见 `ref_code/AGENTS.md`）；可留空后补 |
| 8 | 是否从兄弟项目迁移内容（research/ 笔记、共享知识库软链等）？ | 按需复制；不进 git 的软链走 `.git/info/exclude` |
| 9 | 是否保留 `tasks/`（实验队列）与 `docs/`（机制知识库）？ | 默认**都保留**——实验型项目的通用机制。轻量项目可删，删除时同步清理 AGENTS.md 目录结构条目与对应目录 |

说明：

- **问题 2 务必实测，不要凭惯例猜**。SSH 上去：`touch` 验证基目录可写、`df -h` 看磁盘、记录哪些大存储对当前用户**只读**（常见坑：dolphinfs/nfs 类共享盘往往 root 所有不可写）。结论写入 AGENTS.md `Environment` 段（远端目录、磁盘、只读告警）。
- mutagen target 是 **per-repo** 的：本地 `<项目根>/code/<repo>` ↔ `{{REMOTE_BASE}}/<repo>`。`code/` 是容器目录，不做整体同步。
- 问题 6 的常见情形：开发基线来自某 PR 时，PR head 分支通常在作者组织仓库（非个人 fork），直接克隆该分支即可拿到 PR 代码。

## Step 2 · 替换占位符

替换以下文件中的占位符（严格按用户确认的值）：

| 文件 | 占位符 |
|------|--------|
| `AGENTS.md` | `{{PROJECT_NAME}}`、`{{PROJECT_GOAL}}`、`{{REMOTE_BASE}}` |
| `.mutagen/sync.sh` | `SESSION_PREFIX`（=项目名）、`REMOTE_BASE`（=服务器基目录）；若 Step 1 问题 6 已知首个仓库名，按配置区注释三步登记 target |

替换后校验：`grep -rn '{{' .` 应无结果（`sync.sh` 防呆守卫自身的 `'{{'` 模式串除外；INIT.md 自身删除前除外）。

## Step 3 · 定制内容

按 Step 1 收集的信息调整：

- **Project Goal**: 用户原话整理成 2-5 句，写清"做什么、为什么、关键手段"。
- **实验流程**: 按实验形态细化：GPU 训练类在"预检"写"验证 GPU/Ray 资源空闲"、推理服务类写"启动服务、验证端口与就绪探针"、纯本地项目可整段简化或删除。
- **Hard Rules**: 与用户确认两档分级的适用范围：哪些实验属"默认放行"（低风险脚本类）、哪些属"必须请示"（完整系统链路），改写两档清单举例。
- **`tasks/`**: 按需调整 `tasks/AGENTS.md`（优先级词表、ID 命名约定等）；决定不保留则删除整个 `tasks/`，并清理 AGENTS.md 目录结构中的对应条目。
- **`docs/`**: 在 `docs/AGENTS.md`「组织约定」中定义本项目的分类词表（封闭集合），并同步 `docs/README.md` 的索引板块；决定不保留则删除整个 `docs/`，并清理 AGENTS.md 对应条目。
- **`scripts/` 规范**: 按项目需要增删 `scripts/AGENTS.md` 中的规范；决定不保留则删除该文件，并清理 AGENTS.md 对应条目。
- **`TERMS.md`**: 可留空后补；不使用术语表机制则删除该文件及 AGENTS.md「术语约定」节。
- **Devlog 纪律**: "关键指标"举例按项目类型调整（loss、reward、吞吐、命中率、加速比等）。
- **devlog/INDEX.md 分类**: 按项目性质调整"实验结论 / 实验数据 / 算法设计 / 基础设施"分类，可增删。
- **Environment**: 写入问题 2 的实测结论（远端目录、磁盘、只读告警等服务器事实）。
- **Key Technical Decisions / Key File Paths**: 与用户确认初始内容，没有可留空占位段。

## Step 4 · 初始化动作（按需，逐项与用户确认）

- [ ] `git init`（项目根仓库）+ 首次提交（`.gitignore` 已就绪，已忽略 `code/`）
- [ ] **`code/` 不要 git init**：它是容器目录，各子仓库克隆/初始化时自带 `.git`
- [ ] 需要时按 `ref_code/AGENTS.md` 流程克隆参考代码并登记（含 `.git/info/exclude` 配置）
- [ ] 需要时从兄弟项目迁移 research/ 等内容
- [ ] **mutagen 同步不急于启动**：`code/` 还没有仓库时无需同步。首个仓库就位并登记 target 后再启动（见附录 A 第 4 步），远端基目录缺失时先 `ssh <host> mkdir -p <base>`

## Step 5 · 校验

- [ ] `grep -rn '{{' .` 无残留（`sync.sh` 防呆守卫的模式串除外）
- [ ] AGENTS.md 顶部 TEMPLATE NOTICE 注释已删除
- [ ] 保留/删除的模块与目录一致：`tasks/`、`docs/`、`scripts/AGENTS.md`、`TERMS.md` 如保留则存在且被 AGENTS.md 引用，如删除则 AGENTS.md 无残留引用
- [ ] `git status` 无意外未跟踪文件（`.codegraph`/`.omo/` 已被 `.gitignore` 忽略）
- [ ] 若已登记 target：`bash .mutagen/sync.sh <repo> status` 输出正常；未登记时 `bash .mutagen/sync.sh all status` 不报错

## Step 6 · 收尾

删除本文件（INIT.md），然后提交：

```
chore: initialize from template
```

---

## 附录 A · 新增 `code/` 仓库的常规流程（初始化后参考）

1. **克隆/初始化**：`git clone --branch <branch> <url> code/<repo>`；开发基线来自 PR 时克隆 PR head 分支，并记录起始 commit。
2. **分支布局**：保留跟踪分支（只读，用于 `git fetch` + 跟进上游），另建开发分支在上面工作；基线来自 fork/PR 时可加 `upstream` remote 指向官方仓库（只拉不推）。
3. **登记同步 target**：`.mutagen/sync.sh` 配置区三步（`*_REMOTE` 变量 / `resolve_target()` 分支 / `ALL_TARGETS`）。
4. **启动同步**（可选）：`bash .mutagen/sync.sh <repo> start`，`all status` 验证；远端仓库子目录缺失时 mutagen 自动创建（前提：基目录存在）。
5. **记录**：基线来源、commit、remote/分支布局写入 devlog 并登记 INDEX.md。

## 附录 B · ref_code 与迁移内容的区别

- `ref_code/`：**只读**外部参考（固定版本浅克隆，登记于 `ref_code/AGENTS.md`，git 忽略走 `.git/info/exclude`），用于核对语义/对比实现。
- 需要基于 ref 修改的代码：克隆进 `code/<repo>` 作为独立开发仓库，走附录 A 流程。
- 从兄弟项目迁移的笔记/文档：放 `research/`，由根仓库 git 跟踪；指向本机共享知识库的软链若不跟踪，加 `.git/info/exclude`。