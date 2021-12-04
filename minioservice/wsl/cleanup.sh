#!/bin/bash

function is_running_as_root
{
	is_root_set=0
	if [ "$EUID" -ne 0 ]; then
  	    echo "Please run as root"
    else
        is_root_set=1
	fi
    return $is_root_set
}

if is_running_as_root -eq 0; then
    exit
fi

service minio stop 2>/dev/null || true

rm -rf /etc/init.d/minio

rm -rf /usr/local/bin/minio
rm -rf /usr/local/bin/miniolauncher.sh

rm -rf /var/run/minio

echo "Cleaning user for Minio daemon"
if id "minio-user" &>/dev/null; then
    echo 'user found minio-user. Deleting.'
    userdel minio-user
else
    echo 'user not found. Nothing to delete.'
fi

