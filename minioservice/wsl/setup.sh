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

# Download minio to /usr/local/bin for the service to use it. Skip download if minio exists.
#
MINIO=/usr/local/bin/minio
if test -f "$MINIO"; then
    echo "minio executable exists at $(which minio). No need to download."
else
    echo "Downloading Minio executable to /usr/local/bin"
    wget https://dl.min.io/server/minio/release/linux-amd64/minio -P /usr/local/bin
    chmod +x /usr/local/bin/minio
fi

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


if test -f "/usr/local/bin/miniolauncher.sh"; then
    echo "miniolauncher executable exists at $(which minio). No need to copy."
else
    echo "Copying Minio launcher to /usr/local/bin"
    cp $SCRIPT_DIR/miniolauncher.sh /usr/local/bin/miniolauncher.sh
    chmod +x /usr/local/bin/minio
fi

echo "Creating user for Minio daemon"
if id "minio-user" &>/dev/null; then
    echo 'user found minio-user. Not creating.'
else
    echo 'user not found. Creating minio-user'
    useradd minio-user
fi

echo "Copying minio service configuration to /etc/init.d/minio"
cp $SCRIPT_DIR/minioservice /etc/init.d/minio

echo "Creating minio data folders "
mkdir -p /tmp/minio/data{1..8}


mkdir -p /etc/minio
mkdir -p /var/run/minio 
chown minio-user:minio-user /var/run/minio

echo "Start the service with command  [service minio start]"
service minio start 

echo "Getting status of the minio service"
service minio status
