#!/bin/bash

find /srv/docker/redmine/redmine/backups/ -mtime +15 -name "*" -exec rm -rf {} \;

rsync -av --delete /srv/docker/redmine/redmine/backups/ /opt/Data_backups/
