#!/bin/bash
tail -F /var/log/auth.log | ./notify-login.sh > /dev/null 2>&1 &