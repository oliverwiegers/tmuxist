
# exit the script if any statement returns a non-true return value
set -e

eval "$(cut -c3- ~/.tmux.conf.local)"
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
    tty=${1:-$(tmux display -p '#{pane_tty}')}
    if ! type _username_override > /dev/null 2>&1; then
        tty_stats="$(_tty_stats "${tty}")"
        username="${tty_stats#*:}"
        cmdline="${username#*:}"
        username="${username%%:*}"
        if _is_ssh "${cmdline}";then
            ssh_stats="$(_ssh_stats "${cmdline}")"
            printf '%s' "${ssh_stats%%:*}"
        else
            if [ "${username}" = "caffeinate" ];then
                username="$(hostname)"
            fi
            printf '%s' "${username}"
        fi
    else
        _username_override "${tty}"
    fi
    if [ "${username}" = "root" ]; then
        tmux set-environment -g tmux_user_root 'root'
    else
        tmux set-environment -g tmux_user_root ''
    fi
}

_hostname() {
    tty=${1:-$(tmux display -p '#{pane_tty}')}
    if ! type _hostname_override > /dev/null 2>&1; then
        tty_stats="$(_tty_stats "${tty}")"
        cmdline="${tty_stats#*:}"
        cmdline="${cmdline#*:}"
        printf 'nope'
        if _is_ssh "${cmdline}";then
            ssh_stats="$(_ssh_stats "${cmdline}")"
            printf '%s' "${ssh_stats##*:}"
        else
            printf '%s' "$(uname -n)"
        fi
    else
        _hostname_override "${tty}"
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

_battery_stats() {
    if ! [ -d "$HOME/.cache" ]; then
        mkdir -p "$HOME/.cache"
    fi

    _cleanup_tmp() {
        percent="$1"
        tmp_file_path="$HOME/.cache/tmux_battery_alert_${percent}"
        if [ -f "${tmp_file_path}" ]; then
            rm "${tmp_file_path}"
        fi
    }

    batteries="$(\
        find /sys/class/power_supply/ -name 'BAT*' \
        | rev \
        | cut -d '/' -f 1 \
        | rev \
        )"
    output=''
    output_icon=''
    for battery in ${batteries}; do
        battery_path="/sys/class/power_supply/${battery}"
        status="$(cat "${battery_path}/status")"
        capacity="$(cat "${battery_path}/capacity")"
    
        if ! [ "${status}" = 'Discharging' ]; then
            output_icon=''
            _cleanup_tmp "*"
        else
            if [ "${capacity}" -le 100 ]; then
                output_icon=''
                _cleanup_tmp "*"
            elif [ "${capacity}" -lt 80 ]; then
                output_icon=''
                _cleanup_tmp "*"
            elif [ "${capacity}" -lt 50 ]; then
                output_icon=''
                _cleanup_tmp "*"
            elif [ "${capacity}" -lt 15 ]; then
                output_icon=''
                _cleanup_tmp "5"
                if ! [ -f "$HOME/.cache/tmux_battery_alert_15" ]; then
                    if command -v notify-send > /dev/null 2>&1; then
                        ffplay -f lavfi -i "sine=frequency=100:duration=0.1" \
                            -autoexit -nodisp > /dev/null 2>&1
                        notify-send "Alert!" "Battery is below 15%."
                        touch "$HOME/.cache/tmux_battery_alert_15"
                    fi
                fi
            elif [ "${capacity}" -lt 5 ]; then
                output_icon=''
                _cleanup_tmp "15"
                if ! [ -f "$HOME/.cache/tmux_battery_alert_5" ]; then
                    if command -v notify-send > /dev/null 2>&1; then
                        ffplay -f lavfi -i "sine=frequency=100:duration=0.1" \
                            -autoexit -nodisp > /dev/null 2>&1
                        notify-send "Alert!" "Battery is below 5%."
                        touch "$HOME/.cache/tmux_battery_alert_5"
                    fi
                fi
            fi
        fi
    
        output="${output} ${capacity} ${output_icon}"
    done
    
    # Use xargs to strip whitespace.
    printf '%s' "$(printf '%s' "${output}" | xargs)"
}

_pulseaudio_stats() {
    if command -v pactl > /dev/null 2>&1; then
		output=''
		sink_id="$(pactl list short sinks \
			| grep "$(pactl get-default-sink)" \
			| awk '{print $1}')"
		muted="$(pactl list sinks \
			| SINK="${sink_id}" perl -000ne 'if(/#$ENV{SINK}/){/(Mute:.*)/; print "$1\n"}' \
			| awk '{print $2}')"
		volume="$(pactl list sinks \
			| SINK="${sink_id}" perl -000ne 'if(/#$ENV{SINK}/){/(Volume:.*)/; print "$1\n"}' \
			| grep -oE '[0-9]{,3}%' \
			| uniq)"

        # Display delimiter when audio is present.
        tmux set-environment -g has_pulseaudio 1

        if [ "${muted}" = 'yes' ]; then
            output_icon=''
            output="${output_icon}"
        else
            if [ "${volume}" -lt 5 ]; then
                output_icon=''
            elif [ "${volume}" -lt 50 ]; then
                output_icon=''
            else
                output_icon=''
            fi
            output="${volume} ${output_icon}"
        fi

		printf '%s' "${output}"
    else
        # Remove delimiter when no audio is present.
        tmux set-environment -g has_pulseaudio 0
    fi
}

_network_stats() {
	interfaces="$(\
		find /sys/class/net/ -type l \
		| rev \
		| cut -d '/' -f 1 \
		| rev \
		)"
	output='No network!'
	wifi_icon=''
	ethernet_icon=''
	
	for interface in ${interfaces}; do
		if ! ip link show "${interface}" | grep -q DOWN; then
			interface_path="/sys/class/net/${interface}"
			devtype="$(grep DEVTYPE "${interface_path}/uevent" | cut -d '=' -f 2)"
			status="$(cat "${interface_path}/carrier")" || true
			if [ "${devtype}" = 'wlan' ] \
				|| [ "${devtype}"  = 'ethernet' ] \
				|| [ "${devtype}"  = 'wwan' ] ; then

				if [ "${status}" -eq 1 ]; then
					# Display delimiter when no network is online.
					tmux set-environment -g has_network 1
	
					ip="$(ip addr show "${interface}" \
						| grep -E 'inet [1-9]{,3}\.[1-9]{,3}\.[1-9]{,3}\.[1-9]{,3}' \
						| awk '{print $2}' \
						| cut -d '/' -f 1 \
						)"
					if printf '%s' "${devtype}" | grep -q 'wlan'; then
						output="${ip} ${wifi_icon}"
					elif printf '%s' "${devtype}" | grep -q 'wwan'; then
						output="${ip} ${wifi_icon}"
					elif printf '%s' "${devtype}" | grep -q 'ethernet'; then
						output=${ip} "${ethernet_icon}"
					fi
				fi
			fi
		fi
	done
	
	# Use xargs to strip whitespace.
	printf '%s' "$(printf '%s'  "${output}" | xargs)"
}

"$@"
