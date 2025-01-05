#!/bin/bash

docker run -d -v /mnt/movies/nextcloud/nextcloud:/var/www/html -v /mnt/movies/nextcloud/apps:/var/www/html/custom_apps -v /mnt/movies/nextcloud/config:/var/www/html/config -v /mnt/movies/nextcloud/data:/var/www/html/data -d -p 8090:80 nextcloud

