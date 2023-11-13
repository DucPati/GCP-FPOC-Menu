#!/bin/bash

#Set colour variables
Black='\'033'\e'[30m
Red='\'033'\e'[31m
Green='\'033'\e'[32m
Brown='\'033'\e'[33m
Blue='\'033'\e'[94m
Purple='\'033'\e'[95m
Cyan='\'033'\e'[36m
Grey='\'033'\e'[37m
Yellow='\'033'\e'[33m


while true; do
    clear
    cd /home/iamcse/logs #Set log directory
    echo -e "${Yellow}"
    ls -last
    echo
    echo -e "${Grey}Newest files listed at top"
    echo -e "Copy/Paste the log file you wish to monitor: "
    echo -e "Hit Ctrl+C then q to quit logfile display"
    echo 
    read -e -p "" logfile
    less +F $logfile
    exit
done
