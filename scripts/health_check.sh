#!/usr/bin/env bash
# CPU & Disk usage check. Exit 1 if any crosses the limit.
set -uo pipefail

CPU_LIMIT="${CPU_LIMIT:-80}"
DISK_LIMIT="${DISK_LIMIT:-80}"

cpu_usage() {
  # Read /proc/stat twice, 1 sec apart -> accurate CPU %
  read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
  sleep 1
  read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
  local idle1=$((i1 + w1)) idle2=$((i2 + w2))
  local tot1=$((u1 + n1 + s1 + i1 + w1 + q1 + sq1))
  local tot2=$((u2 + n2 + s2 + i2 + w2 + q2 + sq2))
  local dt=$((tot2 - tot1)) di=$((idle2 - idle1))
  [ "$dt" -le 0 ] && { echo 0; return; }
  echo $(( (100 * (dt - di)) / dt ))
}

disk_usage() {
  df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

CPU=$(cpu_usage)
DISK=$(disk_usage)

echo "===== HEALTH CHECK ($(date '+%F %T')) ====="
echo "Host       : $(hostname)"
echo "CPU Usage  : ${CPU}% (limit ${CPU_LIMIT}%)"
echo "Disk Usage : ${DISK}% (limit ${DISK_LIMIT}%)"

if [ "$CPU" -gt "$CPU_LIMIT" ] || [ "$DISK" -gt "$DISK_LIMIT" ]; then
  echo "STATUS: FAIL"
  exit 1
fi
echo "STATUS: PASS"
