#!/system/bin/sh

MODDIR=${0%/*}
LOG="$MODDIR/screenshot-hires.log"
CONF="$MODDIR/resolution.conf"

# Function to capture volume key press
get_vol_key() {
   # Clear key event buffer
   timeout 1 getevent -c 1 >/dev/null 2>&1

   while true; do
      local event=$(timeout 0.3 getevent -l -c 1 2>/dev/null | grep -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN")
      
      if echo "$event" | grep -q "KEY_VOLUMEUP"; then
         echo "UP"
         return 0
      elif echo "$event" | grep -q "KEY_VOLUMEDOWN"; then
         echo "DOWN"
         return 0
      fi
      sleep 0.1
   done
}

# Resolution Options Table
OPT_1_L="Disable (Restore Default)"; OPT_1_W=0; OPT_1_H=0
OPT_2_L="2K 16:9 (2560x1440)"; OPT_2_W=2560; OPT_2_H=1440
OPT_3_L="2K 1:1  (2048x2048)"; OPT_3_W=2048; OPT_3_H=2048
OPT_4_L="3K 16:9 (3200x1800)"; OPT_4_W=3200; OPT_4_H=1800
OPT_5_L="3K 1:1  (3072x3072)"; OPT_5_W=3072; OPT_5_H=3072
OPT_6_L="4K 16:9 (3840x2160)"; OPT_6_W=3840; OPT_6_H=2160
OPT_7_L="4K 1:1  (3840x3840)"; OPT_7_W=3840; OPT_7_H=3840
OPT_8_L="Keep Current Settings"; OPT_8_W=-1; OPT_8_H=-1

TOTAL_OPTS=8
CURRENT_IDX=1

draw_menu() {
   # Clear screen to remove previous Vol UP scroll logs
   clear 2>/dev/null || printf "\033[H\033[2J"

   echo "================================="
   echo " Pico Screenshot Resolution Setup"
   echo "================================="
   echo " CONTROLS:"
   echo "  • [Vol UP]   = Next Item"
   echo "  • [Vol DOWN] = Select"
   echo "---------------------------------"
   echo " RESOLUTION OPTIONS:"

   # Print the full list and highlight the active option
   for i in $(seq 1 $TOTAL_OPTS); do
      eval ITEM_L=\$OPT_${i}_L
      if [ $i -eq $CURRENT_IDX ]; then
         echo "  [➔] $i. $ITEM_L"
      else
         echo "      $i. $ITEM_L"
      fi
   done

   echo "---------------------------------"
}

while true; do
   draw_menu
   
   KEY=$(get_vol_key)
   
   if [ "$KEY" = "DOWN" ]; then
      eval CONFIRMED_L=\$OPT_${CURRENT_IDX}_L
      echo " "
      echo " [✓] Selected: $CONFIRMED_L"
      break
   elif [ "$KEY" = "UP" ]; then
      CURRENT_IDX=$((CURRENT_IDX + 1))
      if [ $CURRENT_IDX -gt $TOTAL_OPTS ]; then
         CURRENT_IDX=1
      fi
      sleep 0.1
   fi
done

eval FINAL_W=\$OPT_${CURRENT_IDX}_W
eval FINAL_H=\$OPT_${CURRENT_IDX}_H

if [ "$FINAL_W" -eq -1 ]; then
    echo "================================="
    echo " No changes have been made."
    echo " [✓] Done."
else
    echo "================================="
    echo " Executing settings command now..."
    echo "================================="

    # RUN COMMANDS IMMEDIATELY
    settings put global pvr.video.resolution.width $FINAL_W
    settings put global pvr.video.resolution.height $FINAL_H

    echo " Applied width:  $FINAL_W"
    echo " Applied height: $FINAL_H"
    echo " [✓] Screen resolution updated!"
    echo " Try taking a screenshot now."

    # Write selected resolution to config file for service.sh to use on boot.
    if [ "$FINAL_W" -eq 0 ]; then
        echo "ENABLE=0" > "$CONF"
    else
        printf 'ENABLE=1\nW=%s\nH=%s\n' "$FINAL_W" "$FINAL_H" > "$CONF"
    fi
    echo "================================="
    echo " Configuration saved for reboots."
    echo " [✓] Done."
fi