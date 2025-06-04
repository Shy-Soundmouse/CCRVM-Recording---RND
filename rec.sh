#!/bin/bash

# Goal of this script is to put recording server into idea status - only 1 recording process (and children) for each channel

cd /home/soundmouse/record_udp_feeds || exit

# return 0 if no process found, then should create one
# return 1 if only 1 process found, then do nothing
# return 2 if multiple processes found
# return 3 if errors found, skip this round of operation
function check_ps_duplication() {
  local uniq_searching_text="$1"
  # this will match record|record_* with given text
  resp=$(pgrep -f "$uniq_searching_text")
  pgrep_code=$?
  if [ $pgrep_code -eq 1 ]; then # means no process found
    return 0
  elif [ $pgrep_code -eq 0 ]; then # process(es) found
    ps_count=$(echo "$resp" | wc -l | tr -cd '[:digit:]')
    if [ -z "$ps_count" ]; then
      echo "get empty ps count for $uniq_searching_text" >&2
      return 3
    elif [ "$ps_count" -eq 1 ]; then
      return 1
    else
      return 2
    fi
  else # errors
    echo "can't get process count of $uniq_searching_text, operation skipped" >&2
    return 3
  fi
}

# leave the latest process and kill others
function kill_except_latest() {
  local uniq_searching_text="$1"
  latest_pid=$(pgrep -nf "$uniq_searching_text")
  other_pids=$(pgrep -f "$uniq_searching_text" | grep -vE "^${latest_pid}$")
  for p in $other_pids; do
    child_processes=$(pstree -p "$p" | grep -oP '\(\K\d+(?=\))')
    echo "kill -9 $p $child_processes"
    kill -9 $p $child_processes
  done
}


for a in $(cat *.tv); do
  u=$(echo $a | cut -d"|" -f1)  # e.g. udp://239.100.12.7:2246
  c=$(echo $a | cut -d"|" -f2)  # e.g. GBT249ITV1BorderScot_sb8_s0
  s=$(echo $a | cut -d"|" -f3)
  check_ps_duplication "rec.*$c"
  e_code=$?
  if [ $e_code -eq 1 ]; then # already a recording process running
    continue
  elif [ $e_code -eq 0 ]; then # start a new recording process
    if [ "$s" == "rtl" ]; then
      ./record_rtl.sh "$u" "$c" &
    else
      ./record_ffmpeg.sh "$u" "$c" &
    fi
  elif [ $e_code -eq 2 ]; then # multiple recordings
    kill_except_latest "rec.*$c"
  else # errors, already logged
    continue
  fi
done
