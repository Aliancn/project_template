# INIT — 项目初始化手册（供 AI 执行）

> 本文件是模板初始化的操作手册。AI 与用户逐项确认后，按步骤完成替换和定制，最后删除本文件。

## Step 0 · 前置检查

- [ ] 确认当前目录是复制自 `project_template` 的新项目目录（而不是模板本体）。
- [ ] `AGENTS.md` 顶部应有 TEMPLATE NOTICE 注释；若无，说明已初始化过，停止并询问用户。

## Step 1 · 收集信息（向用户询问，逐项确认）

| # | 问题 | 用途 |
|---|------|------|
| 1 | 项目名？ | `{{PROJECT_NAME}}`：AGENTS.md 标题、mutagen 会话前缀 |
| 2 | 服务器路径（`host:dir` 格式）？ | `{{REMOTE_PATH}}`：AGENTS.md 路径表、sync.sh |
| 3 | 项目目标（2-5 句：做什么、为什么、关键手段）？ | `{{PROJECT_GOAL}}`：AGENTS.md Project Goal 段 |
| 4 | 实验形态？（GPU 训练 / 推理服务 / 数据处理 / 其他） | 定制 AGENTS.md "实验流程" 措辞、devlog 指标 |
| 5 | 是否多服务器/多目录同步？ | 单 target（code）保持默认；多 target 在 sync.sh 配置区登记 |
| 6 | 需要哪些参考代码（baseline/对比系统）？ | 按需克隆进 `ref_code/`（流程见 `ref_code/AGENTS.md`），登记版本与用途 |
| 7 | （可选）是否保留 mutagen 同步机制？ | 若纯本地项目，删除 `.mutagen/` 及 AGENTS.md 相关章节 |

说明：

- 问题 2 若用户尚未确定，保留占位符并在 AGENTS.md 路径表标注 `*(待确认)*`，sync.sh 的防呆守卫会阻止误运行，用户后续手工补。
- mutagen 只同步 `code/` 目录，本地路径由脚本自动取 `<项目根>/code/`，无需配置。
- `REMOTE_PATH` 格式为 `host:dir`（如 `my-server:/workdir/myproj`）。
- 多 target：每个 target 需在 sync.sh 顶部配置区填一对 `*_REMOTE` 变量 + `resolve_target()` 登记 + `ALL_TARGETS` 登记，本地目录须为项目根下同名目录。
- `ref_code/` 在初始化时按需克隆（如已有明确 baseline），也可随研究进展随时按 `ref_code/AGENTS.md` 流程新增；详见该文件的约定与登记表。

## Step 2 · 替换占位符

替换以下文件中的占位符（严格按用户确认的值）：

| 文件 | 占位符 |
|------|--------|
| `AGENTS.md` | `{{PROJECT_NAME}}`、`{{PROJECT_GOAL}}`、`{{REMOTE_PATH}}` |
| `.mutagen/sync.sh` | `SESSION_PREFIX`（=项目名）、`CODE_REMOTE`（=服务器路径）两个变量的值；多 target 时继续填入其余 `*_REMOTE` 变量并取消对应注释 |

替换后校验：`grep -rn '{{' .` 应无结果（若 Step 1 允许保留待补，记录清单告知用户）。

## Step 3 · 软链接处理

确认 `CLAUDE.md -> AGENTS.md` 相对软链接存在且有效：

```bash
ls -l CLAUDE.md
```

若软链接在复制/解包过程中丢失（或变成实体文件），重建：

```bash
ln -sf AGENTS.md CLAUDE.md
```

## Step 4 · 定制内容

按 Step 1 收集的信息调整 AGENTS.md：

- **Project Goal**: 用用户原话整理成 2-5 句，写清"做什么、为什么、关键手段"。
- **实验流程**: 该节为阶段化骨架（预检→准备→提交→监控→验证→记录），明确标注了"可根据项目实际情况动态调整、增删步骤"及自进化机制。初始化时按实验形态细化：GPU 训练类在"预检"写"验证 GPU/Ray 资源空闲"、推理服务类写"启动服务、验证端口与就绪探针"、纯本地项目可整段简化或删除。
- **Hard Rules**: 与用户确认"实验启停需批准"规则的适用范围（举例是否合适、是否要加其他红线）。
- **Devlog 纪律**: "关键指标"举例按项目类型调整（loss、reward、耗时、吞吐等）。
- **devlog/INDEX.md 分类**: 按项目性质调整"实验结论 / 算法设计 / 基础设施"分类，可增删。
- **Key Technical Decisions / Environment / Key File Paths**: 与用户确认初始内容，没有可留空占位段。

## Step 5 · 初始化动作（按需，逐项与用户确认）

- [ ] `git init`（项目根仓库）+ 首次提交（`.gitignore` 已就绪，其中已忽略 `code/`）
- [ ] `cd code/ && git init`（独立代码仓库，与根仓库分离）
- [ ] 需要时按 `ref_code/AGENTS.md` 流程克隆参考代码并登记（含 `.git/info/exclude` 配置）
- [ ] 服务器上创建远端目录
- [ ] `bash .mutagen/sync.sh code start` 启动同步并验证（`all status` 确认正常）
- [ ] 需要时创建被 ignore 的目录（`logs/`、`scratch/` 等，只存在于服务器/本地工作区，不进 git）

## Step 6 · 校验

- [ ] `grep -rn '{{' .` 无残留（INIT.md 自身除外，见下一项）
- [ ] AGENTS.md 顶部 TEMPLATE NOTICE 注释已删除
- [ ] `CLAUDE.md -> AGENTS.md` 软链接有效
- [ ] `bash .mutagen/sync.sh all status` 输出正常（若启用同步；多 target 时各 target 均已登记）

## Step 7 · 收尾

删除本文件（INIT.md），然后提交：

```
chore: initialize from template
```
