#!/bin/bash
rsync -az --delete $HOME/ /tmp/backup
if [ $? -eq 0 ]; then
    logger -t backup "The backup of directory  $HOME has been made to catalog /tmp/backup/"
else
    logger -t backup "ERROR: Backup of directory $HOME failed"
fi