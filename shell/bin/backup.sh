#!/usr/bin/env bash
# Simple script to backup MyData partition to external storage
MACHINE="$(uname -n)"
BACKUP_DATE="$(date +%Y-%m-%d)"
rsync -avzh --progress /run/media/davi/MyData/* /run/media/davi/Seagate3T/Backups/$(MACHINE)-MyData-$(BACKUP_DATE)/
