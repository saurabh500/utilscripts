# Volume to be used for MinIO server.
MINIO_VOLUMES="/tmp/minio/"
# Use if you want to run MinIO on a custom port.
MINIO_OPTS="--console-address :9001"
# Root user for the server.
MINIO_ROOT_USER=Root-User
# Root secret for the server.
MINIO_ROOT_PASSWORD=Root-Password
export MINIOVOLUMES=/tmp/minio/data{1...8}
DAEMONOPTS="server ${MINIOVOLUMES} --console-address :9001"

DAEMON=$(which minio)

export MINIO_ROOT_PASSWORD=Password
export MINIO_ROOT_USER=minioadmin

$DAEMON $DAEMONOPTS 
