#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/mutagen.yml"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ============ 同步目标配置（初始化时填前两项，仓库 target 随克隆登记，见 INIT.md） ============
SESSION_PREFIX="{{PROJECT_NAME}}"

# 服务器端仓库基目录（host:dir），各仓库映射为 本地 <项目根>/code/<repo> ↔ REMOTE_BASE/<repo>
REMOTE_BASE="{{REMOTE_BASE}}"

# 每个仓库一个 target，登记三步：
#   ① 此处加 *_REMOTE 变量（推荐写成 "${REMOTE_BASE}/<repo>"）
#   ② resolve_target() 加同名分支（TARGET_LOCAL 固定取 <项目根>/code/<repo>）
#   ③ ALL_TARGETS 登记
# 示例（code/ 下克隆了 verl 仓库后）：
# VERL_REMOTE="${REMOTE_BASE}/verl"

# target 总表（空格分隔；code/ 尚无仓库时留空）
ALL_TARGETS=""
# ALL_TARGETS="verl sglang"
# ================================================================

# 防呆守卫：模板未初始化时禁止运行（见 INIT.md）
if [[ "${SESSION_PREFIX}" == *'{{'* || "${REMOTE_BASE}" == *'{{'* ]]; then
    echo "ERROR: 模板尚未初始化，请先按 INIT.md 完成初始化。" >&2
    exit 1
fi

usage() {
    cat <<EOF
Usage: $(basename "$0") <target> <action>

Targets:
  <repo>     已登记的仓库 target（当前：${ALL_TARGETS:-无}）
  all        Operate on all targets

Actions:
  start      Create and start the sync session
  stop       Terminate the sync session
  status     List all sync sessions
  monitor    Monitor the sync session in real-time
  flush      Force a full sync cycle
  pause      Pause the sync session
  resume     Resume the sync session
  restart    Stop then start the sync session

Examples:
  $(basename "$0") verl start       # 启动 verl 同步（示例，替换为实际 target）
  $(basename "$0") verl pause       # 暂停（切 git 分支前必须暂停）
  $(basename "$0") all status       # 查看所有会话
EOF
}

session_name()   { echo "${SESSION_PREFIX}-${1}"; }
# 注意：不能写成 `mutagen sync list | grep -q`——pipefail 下 grep -q 提前退出会让
# 上游收到 SIGPIPE 而误判"不存在"（session 存在且输出较长时必现）。先缓冲再匹配。
session_exists() {
    local list
    list="$(mutagen sync list 2>/dev/null || true)"
    [[ "${list}" == *"Name: $(session_name "$1")"* ]]
}

resolve_target() {
    local t="$1"
    case "$t" in
        # verl)
        #     TARGET_LOCAL="${PROJECT_ROOT}/code/verl"
        #     TARGET_REMOTE="${VERL_REMOTE}"
        #     ;;
        *)
            echo "ERROR: Unknown target '${t}'（尚未登记该仓库的 target？见本文件顶部配置区）" >&2
            usage >&2
            exit 1
            ;;
    esac
}

cmd_start() {
    local target="$1"
    resolve_target "$target"
    local session
    session="$(session_name "$target")"
    if session_exists "$target"; then
        echo "Session '${session}' already exists."
        return 0
    fi
    mkdir -p "${TARGET_LOCAL}"
    echo "Creating sync session '${session}'..."
    echo "  ${TARGET_LOCAL}  ←→  ${TARGET_REMOTE}"
    mutagen sync create \
        --name="${session}" \
        --configuration-file="${CONFIG_FILE}" \
        "${TARGET_LOCAL}" \
        "${TARGET_REMOTE}"
    echo ""
    echo "Session created. Run '$(basename "$0") ${target} monitor' to watch progress."
}

cmd_stop() {
    local target="$1"
    resolve_target "$target"
    local session
    session="$(session_name "$target")"
    if ! session_exists "$target"; then
        echo "Session '${session}' does not exist."
        return 0
    fi
    echo "Terminating session '${session}'..."
    mutagen sync terminate "${session}"
    echo "Done."
}

cmd_monitor() { mutagen sync monitor "$(session_name "$1")"; }
cmd_flush()   { mutagen sync flush "$(session_name "$1")"; }
cmd_pause()   { mutagen sync pause "$(session_name "$1")"; }
cmd_resume()  { mutagen sync resume "$(session_name "$1")"; }
cmd_status()  { mutagen sync list; }

cmd_restart() { cmd_stop "$1"; sleep 1; cmd_start "$1"; }

run_for_targets() {
    local action="$1" target="$2"
    if [ "$action" = "status" ]; then
        # status 列出所有会话，无需按 target 遍历
        cmd_status
        return 0
    fi
    if [ "$target" = "all" ]; then
        if [ -z "${ALL_TARGETS}" ]; then
            echo "ERROR: 尚未登记任何 target（code/ 下还没有仓库？先按本文件顶部配置区登记）" >&2
            exit 1
        fi
        for t in ${ALL_TARGETS}; do
            echo "=== [${action}] ${t} ==="
            "cmd_${action}" "$t" || true
        done
    else
        "cmd_${action}" "$target"
    fi
}

main() {
    local target="${1:-}" action="${2:-}"
    if [ -z "$target" ] || [ -z "$action" ]; then
        usage
        exit 1
    fi

    case "$action" in
        start|stop|status|monitor|flush|pause|resume|restart)
            run_for_targets "$action" "$target"
            ;;
        *)
            echo "ERROR: Unknown action '${action}'" >&2
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"
