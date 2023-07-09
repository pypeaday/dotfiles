#!/bin/bash

$HOME/personal/fancy-motd/motd.sh
# os=`lsb_release -d | awk '{printf "%s %s", $2, $3}'`
# rootFree=`lsblk | awk '{if (length($7)==1) print  $4}'`
# memAvailable=`free -m | grep "Mem" | awk '{printf "%.1fG", $7/1024}'`
# cpuTemp=`echo ?`  #`sensors | grep CPU | awk '{print $2}' | sed 's/+//' | tr -d '\n'`
# loadAvg=`cat /proc/loadavg | awk '{printf "%s %s %s", $1, $2, $3}'`

# printf "

#     __     __  ____
#    ___   __  __    __       @pypeaday
#   __ __ __  _____
#  __   ___  __          漢  $os
# __     __  __            `date`  $memAvailable  辰$loadAvg

# " | lolcat --seed=39 --spread=35
