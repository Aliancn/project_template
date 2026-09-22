# Reference Code

存放 baseline / 对比系统 / 上游项目的源码，**只读查阅**：不编译、不参与 mutagen 同步、不做任何修改。

## 约定（在本目录下工作时适用）

- 每个 ref 一个独立目录（独立 git clone，浅克隆即可），仅供查阅：核对行为语义、对比实现、找参考写法。
- **版本固定**：克隆时锁定 tag/branch，commit 登记到下方登记表；禁止随手 checkout 到其他版本，保证查阅内容与登记版本一致。
- **需要基于 ref 改动时**：复制到项目根的 `code/` 下作为独立副本另建，不要原地修改。
- **git 忽略走 `.git/info/exclude`**（不用 `.gitignore`）：exclude 是 git-only 的本地忽略，不影响读取 `.gitignore` 的代码索引/检索工具；`ref_code/` 内的笔记文档仍被 git 正常跟踪。
- 深入分析（行为语义、对比结论）写入项目根的 `research/` 或 devlog，本目录只放源码与登记信息。

## 新增 ref 流程

```bash
cd ref_code
git clone --depth 1 --branch <tag> <url> <name>          # 浅克隆固定版本；含 LFS 的仓库前加 GIT_LFS_SKIP_SMUDGE=1
cd <name> && git rev-parse HEAD                          # 记下完整 commit
cd ..
echo "ref_code/<name>/" >> "$(git rev-parse --git-dir)/info/exclude"   # git-only 忽略
```

然后在下方登记表填一行，提交本文件（ref_code/AGENTS.md）变更。

> ⚠️ 克隆后**立即**追加 exclude 再 `git add`。误将 ref 仓库 `git add` 会产生 gitlink 条目（mode 160000），需 `git rm --cached ref_code/<name>` 清理。
>
> 注意 `.git/info/exclude` 是本地文件，不随仓库传播；换机器/新 clone 后需按登记表重新克隆并配置。

## 登记表

| 目录 | 项目 | 版本 | commit | 来源 | 用途 |
|------|------|------|--------|------|------|

行格式示例：`| demo/ | DemoSys | v1.2.0 | a1b2c3d | github.com/org/demo | 延迟对比基线；核对缓存淘汰语义 |`

> 登记行的"用途"列写清三件事：对应论文/版本、分析结论住在哪（devlog 编号 / docs 页 / 任务 ID）、与项目的关系与关键结论。登记行是后来者检索 ref 的唯一索引，值得写细。
