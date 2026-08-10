#!/system/bin/sh
# Pico Screenshot HiRes - 手动切换/设置
# 用法:
#   sh toggle.sh on             启用(默认 2560x1440)
#   sh toggle.sh off            关闭(恢复系统默认 1920x1920)
#   sh toggle.sh 3200 1800      设置自定义分辨率并启用
MODDIR=${0%/*}
LOG="$MODDIR/screenshot-hires.log"
CONF="$MODDIR/resolution.conf"

log(){ echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }

case "$1" in
    off)
        settings put global pvr.video.resolution.width  0
        settings put global pvr.video.resolution.height 0
        echo "ENABLE=0" > "$CONF"
        log "turned OFF (restore default 1920x1920)"
        echo "DONE: off"
        ;;
    on)
        W="${2:-2560}"; H="${3:-1440}"
        settings put global pvr.video.resolution.width  "$W"
        settings put global pvr.video.resolution.height "$H"
        printf 'ENABLE=1\nW=%s\nH=%s\n' "$W" "$H" > "$CONF"
        log "turned ON ${W}x${H}"
        echo "DONE: on ${W}x${H}"
        ;;
    *)
        # 自定义: toggle.sh <width> <height>
        if [ -n "$2" ] && [ -n "$3" ]; then
            W="$1"; H="$2"
            settings put global pvr.video.resolution.width  "$W"
            settings put global pvr.video.resolution.height "$H"
            printf 'ENABLE=1\nW=%s\nH=%s\n' "$W" "$H" > "$CONF"
            log "custom ${W}x${H}"
            echo "DONE: ${W}x${H}"
        else
            echo "usage: sh toggle.sh on|off|<width> <height>"
        fi
        ;;
esac
exit 0
