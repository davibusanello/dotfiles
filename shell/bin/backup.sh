#!/usr/bin/env bash
set -e
# Simple script to backup MyData partition to external storage
MACHINE="$(uname -n)"
BACKUP_DATE="$(date +%Y-%m-%d)"
DEST_PATH="/run/media/davi/Seagate3T/BackupsExtra"
rsync -azh --progress /home/davi/* $DEST_PATH/$MACHINE-home-$BACKUP_DATE/

rsync -azh --progress /run/media/davi/MyData/* $DEST_PATH/$MACHINE-MyData-$BACKUP_DATE/
