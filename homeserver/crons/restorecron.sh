#!/bin/bash

crontab -l; cat cron_backup.txt | crontab -

