#!/system/bin/sh
# Pico Screenshot HiRes - 开机设置截图分辨率
# 机制: 截图服务(com.bytedance.pico.screencapture)在每次截图时读取
#   Settings.Global pvr.video.resolution.width / .height
#   只要这两个值非零, 就直接用它们作为截图输出分辨率(无需 hook)
# 默认: 2560x1440 (16:9), 可用 toggle.sh 改成其他值或关闭
MODDIR=${0%/*}
LOG="$MODDIR/screenshot-hires.log"
CONF="$MODDIR/resolution.conf"

log(){ echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }

# 默认配置: 2560x1440, 开关默认开
ENABLE=1
W=2560
H=1440
[ -f "$CONF" ] && . "$CONF"
[ "$ENABLE" = "1" ] || { log "disabled, skip"; exit 0; }

# 等待 boot_completed
n=0
while [ $n -lt 90 ]; do
    [ "$(getprop sys.boot_completed)" = "1" ] && break
    n=$((n+1)); sleep 1
done
log "boot_completed after ${n}s"

# 设置截图分辨率(等 settings 服务就绪)
n=0
ok=0
while [ $n -lt 30 ]; do
    if settings put global pvr.video.resolution.width  "$W" 2>/dev/null \
       && settings put global pvr.video.resolution.height "$H" 2>/dev/null; then
        ok=1
        break
    fi
    n=$((n+1)); sleep 1
done

if [ "$ok" = "1" ]; then
    log "set screenshot resolution -> ${W}x${H}"
else
    log "FAILED to set screenshot resolution"
fi

exit 0
