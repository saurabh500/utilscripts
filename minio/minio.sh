#!/bin/bash -e

PASSWORD_FILE="/var/run/user/scratch/miniocertpass.txt"
if [[ -z "${IP_ADDR}" ]]; then
    ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

    echo "IP_ADDR environment variable hasn't been set. Using $ip4 to create MinIO. To Use a different IP address to expose MinIO, set IP_ADDR env var"

    IP_ADDR=$ip4
fi

# Utility to generate a random string to be used as a password.
generate_random_password() {
     random=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c7)
     upper=$(tr -dc 'A-Z' </dev/urandom | head -c1)
     lower=$(tr -dc 'a-z' </dev/urandom | head -c1)
     digit=$(tr -dc '0-9' </dev/urandom | head -c1)
     echo $(echo $random$upper$lower$digit | fold -w1 | shuf | tr -d '\n')
}

# Set the private key password for minio to use for TLS.
if [[ -z "${MINIO_CERT_PASSWD}" ]]; then
    export MINIO_CERT_PASSWD="$(generate_random_password)"
    echo "MINIO_CERT_PASSWD Environment var does not exist. Generating a random password $MINIO_CERT_PASSWD."
fi

# Set the minio root password if not specified in env var.
if [[ -z "${MINIO_ROOT_PASSWORD}" ]]; then
    export MINIO_ROOT_PASSWORD="$(generate_random_password)"
    echo "MINIO_ROOT_PASSWORD Environment var does not exist. Generating a random password $MINIO_ROOT_PASSWORD."
fi

# Set the minio root user if not specified.
if [[ -z "${MINIO_ROOT_USER}" ]]; then
    export MINIO_ROOT_USER="minioadmin"
    echo "MINIO_ROOT_USER Environment var does not exist. using minioadmin as the minio user."
fi

# Download minio binary if not already available.
MINIO=./minio
if test -f "$MINIO"; then
    echo "minio executable exists. No need to download."
else
    wget https://dl.min.io/server/minio/release/linux-amd64/minio
    chmod +x minio
fi

mkdir -p ./miniodata/data{1..8}
mkdir -p ./miniocert/CAs

# Certificate generation
pushd miniocert

# Generate the openssl config file if not already present.
if test -f "./openssl.conf"; then
    echo "Found openssl.conf. Skipping certificate generation."
else
    # Create Open SSL config.
    echo "openssh.conf was not found. Creating..."
    echo "
    [req]
    distinguished_name = req_distinguished_name
    x509_extensions = v3_req
    prompt = no

    [req_distinguished_name]
    C = US
    ST = VA
    L = Somewhere
    O = MyOrg
    OU = MyOU
    CN = WSL

    [v3_req]
    subjectAltName = @alt_names

    [alt_names]
    IP.1 = 127.0.0.1
    DNS.1 = localhost
    IP.2 = $IP_ADDR
    " > ./openssl.conf
fi

# Generate the private key and certificate. This will overwrite any existing key and certificate. Possible enhancement can be to use pre-existing key and certificate.
echo "Generating private key and certificate."
openssl genrsa -aes256 -passout pass:$MINIO_CERT_PASSWD -out private-pkcs8-key.key 2048
openssl rsa -in private-pkcs8-key.key -aes256  -passin pass:$MINIO_CERT_PASSWD -passout pass:$MINIO_CERT_PASSWD -out private.key
openssl req -new -x509 -nodes -days 730 -key private.key -passin pass:$MINIO_CERT_PASSWD -out public.crt -config openssl.conf

echo "The minio certificate is placed in ./miniocert/public.crt This file would be needed in Root CA of the client interacting with MinIO because this is a self-signed cert."
popd

# Launch minio.
export MINIO_SERVER_URL=https://$IP_ADDR:9000
./minio server ./miniodata/data{1...8} --console-address ":9001" --certs-dir ./miniocert