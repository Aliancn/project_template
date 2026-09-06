#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/mutagen.yml"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ============ 同步目标配置（初始化时修改，见 INIT.md） ============
SESSION_PREFIX="{{PROJECT_NAME}}"

# 默认 target：code（本地 <项目根>/code/ ↔ 服务器）
CODE_REMOTE="{{REMOTE_PATH}}"        # host:dir 格式，如 my-server:/workdir/myproj

# 多服务器/多目录项目：取消注释并在下方 resolve_target() 中登记，
# 本地目录须在项目根下存在同名目录
# CODE_H20_REMOTE="another-server:/workdir/myproj"
# RESPONSE_REMOTE="my-server:/home/user/myproj/response"

# target 总表（新增 target 后在此登记，all 命令按此遍历）
ALL_TARGETS="code"
# ALL_TARGETS="code code-h20 response"
# ================================================================

# 防呆守卫：模板未初始化时禁止运行（见 INIT.md）
if [[ "${SESSION_PREFIX}" == *'{{'* || "${CODE_REMOTE}" == *'{{'* ]]; then
    echo "ERROR: 模板尚未初始化，请先按 INIT.md 完成初始化。" >&2
    exit 1
fi

usage() {
    cat <<EOF
Usage: $(basename "$0") <target> <action>

Targets:
  code       Sync <project>/code/
  all        Operate on all targets (${ALL_TARGETS})

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
  $(basename "$0") code start       # 启动 code 同步
  $(basename "$0") code pause       # 暂停（切 git 分支前必须暂停）
  $(basename "$0") all status       # 查看所有会话
EOF
}

session_name()   { echo "${SESSION_PREFIX}-${1}"; }
session_exists() { mutagen sync list 2>/dev/null | grep -q "Name: $(session_name "$1")"; }

resolve_target() {
    local t="$1"
    case "$t" in
        code)
            TARGET_LOCAL="${PROJECT_ROOT}/code"
            TARGET_REMOTE="${CODE_REMOTE}"
            ;;
        # code-h20)
        #     TARGET_LOCAL="${PROJECT_ROOT}/code-h20"
        #     TARGET_REMOTE="${CODE_H20_REMOTE}"
        #     ;;
        # response)
        #     TARGET_LOCAL="${PROJECT_ROOT}/response"
        #     TARGET_REMOTE="${RESPONSE_REMOTE}"
        #     ;;
        *)
            echo "ERROR: Unknown target '${t}'" >&2
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
