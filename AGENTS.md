<!-- ⚠️ TEMPLATE NOTICE: 本项目尚未初始化。请先阅读 INIT.md 执行初始化流程，完成后删除本注释。 -->

# {{PROJECT_NAME}}

## Project Goal

{{PROJECT_GOAL}}

## 术语约定

对话与文档中的术语、指代与表述约定统一记录在 `TERMS.md`；使用术语前先核对该表，歧义词一经约定即入表。

@TERMS.md

## Devlog Convention

开发日志记录在 `devlog/` 目录下，每个文件是一个独立的主题，命名格式 `{prefix}{MMDDHHSS}_{topic}.md`（如 `07151430_logging_design.md`，`HHSS` 为时分）。涉及多个独立主题时拆分为多个文件，不要写到一个大文件里。文件头部包含日期、问题、影响、后续四个字段，正文记录根因、修复、效果数据和相关文件路径。

**时间戳获取方法**：创建 devlog 文件前，先运行 `date +%m%d%H%M` 获取当前时间戳，用该输出作为文件名中的 `MMDDHHSS`。禁止凭记忆或推测填写时间。

**合并与归档**：同一事件的连续多篇过程记录稳定后，收敛为一篇「统一记录」（读一篇即全貌），旧文移入 `devlog/archive/<事件>_<MMDD>/` 并在 `INDEX.md` 归档节说明新入口。**勘误传播**：修正一处结论时，检索并同步全库相关引用（INDEX / 相关 devlog / docs / README），不只在原地改。

## Directory Structure

**本地/服务器分工**：本地用于代码、日志、大部分文档和结果的编写（源码、devlog、research、实验记录等）；服务器专注于提供运行环境和执行（GPU、集群、编译、长任务）。所有产物最终回传本地沉淀，服务器只留运行态。

- **`code/`**: 源代码**容器目录**，每个子目录一个独立 git 仓库（如 `code/verl/`），与项目根仓库分离（根仓库通过 `.gitignore` 忽略 `code/`）。各子仓库通过 mutagen 与服务器 `{{REMOTE_BASE}}/<repo>` 双向同步（见下文），用于本地编辑代码；代码版本控制、分支切换在本地完成，同步到服务器运行。
- **`devlog/`**: 开发日志，`INDEX.md` 为索引（按"我想看什么"分面组织）。
- **`docs/`**: 项目核心机制知识库（wiki）——长期有效的机制权威描述，另收冻结实验结论（`experiment_result/`）。与 devlog/research 的分工、写法与组织约定见 `docs/AGENTS.md`（子目录级规则，在 `docs/` 下工作时自动加载）。
- **`tasks/`**: 实验任务队列——`TASK.md` 管执行队列，`<id>/design.md` 为实验预注册（设计/数据/测试对象/判据），完成后整体存档到 `archived/`。条目格式与工作循环见 `tasks/AGENTS.md`（子目录级规则，自动加载）。
- **`research/`**: 研究笔记、文献阅读、算法设计文档。
- **`scripts/`**: 实验与运维脚本，按主题分子目录（新主题先建目录，不堆在根下），每个主题目录带一份 `README.md` 作索引。脚本文件头/注释规范与维护纪律见 `scripts/AGENTS.md`（子目录级规则，自动加载）。
- **`ref_code/`**: 参考代码（只读）。存放 baseline/对比系统的源码供查阅，不参与 mutagen 同步、不编译。版本固定，约定与登记表见 `ref_code/AGENTS.md`（子目录级规则，在本目录下工作时自动加载），git 忽略走 `.git/info/exclude`。
- **`TERMS.md`**: 术语与指代约定表（经 `@TERMS.md` 导入本文件「术语约定」节）；使用术语前先核对。

## Mutagen 代码同步

使用 [mutagen](https://mutagen.io) 在本地 `code/` 下各仓库与服务器之间双向同步代码（`two-way-safe` 模式），实现本地编辑 → 自动同步 → 服务器运行的工作流。**每个仓库一个 target**，约定映射：本地 `<项目根>/code/<repo>` ↔ `{{REMOTE_BASE}}/<repo>`；`code/` 本身是容器目录，不做整体同步。

### 路径映射

| 本地 | 服务器 |
|------|--------|
| `<项目根>/code/<repo>/` | `{{REMOTE_BASE}}/<repo>` |

（初始化后把实际仓库行填进来，如 `<项目根>/code/verl/` ↔ `tt:/workdir/verl`）

### 配置与脚本

| 文件 | 用途 |
|------|------|
| `.mutagen/mutagen.yml` | 同步配置：模式、ignore 规则、压缩、权限 |
| `.mutagen/sync.sh` | 管理脚本：`sync.sh <repo> <action>`，action 为 `start`/`stop`/`status`/`monitor`/`flush`/`pause`/`resume`/`restart` |

### 常用命令

```bash
bash .mutagen/sync.sh <repo> start    # 创建并启动该仓库的同步会话
bash .mutagen/sync.sh <repo> monitor  # 实时监控同步状态
bash .mutagen/sync.sh all status      # 查看所有会话
bash .mutagen/sync.sh <repo> flush    # 强制全量同步（网络抖动后恢复用）
bash .mutagen/sync.sh <repo> pause    # 暂停（切 git 分支前必须暂停）
bash .mutagen/sync.sh <repo> resume   # 恢复
bash .mutagen/sync.sh <repo> stop     # 终止会话
```

新增仓库（`code/` 下新子仓库）：在 `.mutagen/sync.sh` 顶部配置区登记 target（`*_REMOTE` 变量 + `resolve_target()` 分支 + `ALL_TARGETS`），支持 `sync.sh <repo> <action>` 与 `sync.sh all <action>`。

### 注意事项

- **切 git 分支前必须 `pause`**，否则大量文件变化可能产生冲突。
- `.so`、`logs/`、`scratch/`、`wheels` 等大体积目录被 ignore，不会同步。
- 同步会话按需启动：`code/` 下尚无仓库或暂不需要同步时不必 start。启动前确认远端基目录存在（`ssh <host> mkdir -p <base>`）；仓库子目录缺失时 mutagen 会自动创建。

## Hard Rules

1. **实验启停审批分级**（初始化时与用户确认两档的适用范围；新红线随时补充到本节）:
   - **默认放行**: 低风险实验——benchmark / 机制验证 / 探针类脚本及其配套 runner 的执行与终止，确认目标资源空闲即可直接执行。
   - **必须请示批准**: 完整系统链路的启动与终止（端到端训练 / 推理服务 / 集群操作等），以及任何有外部影响、难以回滚的操作——必须向用户请示并等待明确批准，不得自行执行。

## Working Methods

### 代码编辑

- **优先本地编辑**: 存在于 `code/` 中的代码文件，直接在本地修改，mutagen 秒级同步到服务器，再到服务器运行。
- **仅本地不存在的文件直接改远端**: 如 `logs/`、`.so`、`scratch/` 等被 ignore 的产物/日志，需要修改时直接 SSH 到服务器操作。
- **需多次远端编辑的文件**: 如果某个被 ignore 的文件需要频繁远端编辑并同步回本地，从 `.mutagen/mutagen.yml` 的 ignore 列表中移除对应规则。
- **git 操作在本地 `code/` 下各仓库执行**: 分支切换、commit、log 等版本操作直接在本地 `code/<repo>/`（各子仓库独立 git 仓库）完成，无需 SSH 到服务器；仅被 ignore 的产物/日志才在服务器上直接操作。

### 实验流程

实验按阶段化的通用骨架执行，每步验证通过后再进入下一步。**以下步骤是初始抽象，可根据项目实际情况动态调整、增删步骤**；具体操作细节（命令、参数、检查项）随研究进行不断补充：

1. **预检**：确认基础设施就绪（隧道/代理/集群状态）、资源空闲、无残留进程；查阅 devlog 中同类实验的经验。
2. **准备**：同步代码、切分支（先 `pause` mutagen）、提交代码、准备配置。
3. **提交**：启动实验。长任务必须在**服务器上的 tmux session** 中运行（SSH 断开不影响进程）；每个长任务一个独立 session，不要在同一 session 里混跑不同批次的任务——杀 session 会杀掉里面所有进程。
4. **监控**：跟踪日志与指标，确认进程存活、输出正常。
5. **验证**：确认实验按预期完成，数据/产物完整。
6. **记录**：结果记入 devlog（含指标、产物路径、代码版本）。

**流程自进化**：新的操作惯例、反复踩的坑、更优的步骤顺序，固化到本节对应步骤下（如：发现某类实验启动前必须先清理某个缓存目录，就在"预检"下补充）；操作细节与根因记入 devlog。本文件膨胀时的拆分规则见下方「文档演进与拆分」。

### 文档演进与拆分

- **固化**：新的约定、惯例、经验坑持续沉淀进本文件对应章节，保持"读 AGENTS.md 即可上手"；操作细节与根因记入 devlog，不堆进本文件。
- **拆分守卫**：若某次更新使本文件某一主题明显膨胀（约定、参数、细节大量堆叠，影响快速通读），应**主动提示用户**是否将该主题拆分为对应子目录下的 AGENTS.md 子文件（子目录级规则自动加载，形态参考 `ref_code/AGENTS.md`、`tasks/AGENTS.md`、`docs/AGENTS.md`、`scripts/AGENTS.md`），主文件只保留一句概述与指向。是否拆分由用户决定，不得自行执行。

### Devlog 记录纪律

- **实验结论**: 每次有效实验记录关键指标（按项目类型确定，如 loss、耗时、吞吐等），并在 `devlog/INDEX.md` 中登记。
- **失败分析**: 实验失败或异常行为必须记录根因分析，不留"不知道为什么"。
- **配置变更**: 关键依赖、框架、环境等配置变更记录决策理由和影响。
- **关键文件路径**: 重要的源码文件、配置文件、脚本路径记录在 devlog 和 AGENTS.md 中，方便快速定位。

## Key Technical Decisions

<!-- 随项目进展在此记录关键技术决策 -->

## Environment

<!-- 随项目进展在此记录运行环境信息（服务器、集群、环境等） -->

## Key File Paths

<!-- 随项目进展在此记录关键源码/配置/脚本路径 -->
