#!/bin/bash

if [[ $(uname) == "Darwin" ]]; then
    $HOME/.macos-motd/motd.sh
else

# Fetching system details
os=$(lsb_release -d | awk '{printf "%-20s %s", $2, $3}')
rootFree=$(lsblk | awk '{if (length($7)==1) print  $4}')
memAvailable=$(free -m | grep "Mem" | awk '{printf "%9.1fG", $7/1024}')
cpuTemp=$(sensors | grep 'Package id 0:' | awk '{print $4}' | sed 's/+//' | tr -d '\n')
loadAvg=$(cat /proc/loadavg | awk '{printf "%9.2f %9.2f %9.2f", $1, $2, $3}')

# Define ASCII art
ascii_art="
    __     __  ____           漢  $(hostname)
   ___   __  __    __
  __ __ __  _____
 __   ___  __          漢  $os
__     __  __            $(date)
"

# Add system stats with borders
stats="
┌─────────────────────────────────────────────────┐
  Memory Available: $memAvailable               
  Root Free Space: $rootFree                   
  CPU Temperature: $cpuTemp                     
  Load Average: $loadAvg                    
└─────────────────────────────────────────────────┘
"

# Print the final MOTD with lolcat
printf "$ascii_art\n$stats\n" | lolcat --seed=39 --spread=35


fi
