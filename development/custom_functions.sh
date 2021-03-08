
# exit the script if any statement returns a non-true return value
set -e

_read_function_overrides() {
    eval "$(cut -c3- ~/.tmux.conf.local)"
}

_is_ssh() {
    cmdline="${1}"
    if ! type _is_ssh_override > /dev/null 2>&1; then
        if [ -z "${cmdline##*ssh *}" ]; then
            return 0
        else
            return 1
        fi
    else
        _is_ssh_override
    fi
}

_ssh_stats() {
    cmdline="${1}"
    if ! type _ssh_stats_override > /dev/null 2>&1; then
        ssh_args="${cmdline#ssh }"
        user_host="$(\
            # shellcheck disable=SC2086
            ssh -G ${ssh_args} |\
            awk '(/^user /) {
                user=$2
            }
            (/^hostname /) {
                hostname=$2
            } END {
                print user":"hostname
                exit
            }
        ')"

        printf '%s' "${user_host}"
    else
        _ssh_stats_override
    fi
}

_tty_stats() {
    tty=${1:-$(tmux display -p '#{pane_tty}')}
    if ! type _tty_stats_override > /dev/null 2>&1; then
        ps -t "${tty}" -o user=WIDEOUTPUTFORLONGNAME -o pid= -o ppid= -o command= | awk '
            NR > 1 && ((/ssh/ && !/-W/) || !/ssh/) {
                users[$2] = $1; parents[$2] = $3; children[$3] = $2; pid=$2; $1 = $2 = $3 = ""; commands[pid] = substr($0,4)
            } END {
                for (ppid in parents) {
                    pid = ppid
                    while (parents[pid])
                    pid = parents[pid]

                    if (!(ppid in children) && pid != 1) {
                        print ppid":"users[ppid]":"commands[ppid]
                        exit
                    }
                }
            }
        '
    else
        _tty_stats_override
    fi
}

_username() {
    tty=${1:-}
    if ! type _username_override > /dev/null 2>&1; then
        tty_stats="$(_tty_stats "${tty}")"
        username="${tty_stats#*:}"
        cmdline="${username#*:}"
        username="${username%%:*}"
        if _is_ssh "${cmdline}";then
            ssh_stats="$(_ssh_stats "${cmdline}")"
            printf '%s' "${ssh_stats%%:*}"
        else
            printf '%s' "${username}"
        fi
    else
        _username_override
    fi
}

_hostname() {
    tty=${1:-}
    if ! type _hostname_override > /dev/null 2>&1; then
        tty_stats="$(_tty_stats "${tty}")"
        cmdline="${tty_stats#*:}"
        cmdline="${cmdline#*:}"
        if _is_ssh "${cmdline}";then
            ssh_stats="$(_ssh_stats "${cmdline}")"
            printf '%s' "${ssh_stats##*:}"
        else
            printf '%s' "$(uname -n)"
        fi
    else
        _hostname_override
    fi
}

_urlview() {
    pane_id="$1"
    if ! type _urlview_override > /dev/null 2>&1; then
        tmux capture-pane -J -S 0 -E - -b "urlview-${pane_id}" -t "${pane_id}"
        tmux split-window -h -l '40%' "tmux show-buffer -b urlview-${pane_id} | urlview || true; tmux delete-buffer -b urlview-${pane_id}"
    else
        _urlview_override
    fi
}

"$@"
