#!/bin/bash

while read line; do
    if [[ $line == *"Authentication: SUCCEEDED"* ]]
    then
      ip="$(grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' <<< "$line")"
      if [ "$ip" != "172.144.255.240" ]
      then
        user="$(grep -oP 'for\s+\K\w+' <<< "$line")"
        notify-send "VNC login detected from $user@$ip"
      fi
    fi

    if [[ $line == *"Accepted password"* ]]
    then
      ip="$(grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' <<< "$line")"
      if [ "$ip" != "172.144.255.240" ]
      then
        user="$(grep -oP 'for\s+\K\w+' <<< "$line")"
        notify-send "SSH login detected from $user@$ip"
      fi
    fi

    if [[ $line == *"sshd"* ]]
    then
      ip="$(grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' <<< "$line")"
      if [ "$ip" != "172.144.255.240" ]
      then
        user="$(grep -oP 'for\s+\K\w+' <<< "$line")"
        notify-send "Access detected from $user@$ip"
      fi
    fi
done