#!/usr/bin/env bash

killall -q polybar
# Wait until the processes have been shut down
while pgrep -x polybar >/dev/null; do sleep 1; done

CONFIG_DIR=$HOME/dotfiles/polybar/config.ini

# Launch polybar
if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    echo "$m"
    # if [[ $m == *"eDP"* ]]; then
    #   echo "skipping laptop monitor"
    # else
    MONITOR=$m 
    export MONITOR=$m

    polybar --reload $POLYBAR_BAR  -c $CONFIG_DIR &
    # fi
  done
else
  polybar --reload $POLYBAR_BAR  -c $CONFIG_DIR &
fi

