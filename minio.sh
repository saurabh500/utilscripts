#!/bin/bash
if [[ -z "${IP_ADDR}" ]]; then
    echo "IP_ADDR environment variable hasn't been set. Exiting."
    exit 1
fi
if [[ -z "${CERTPASS}" ]]; then
    echo "CERTPASS environment variable hasn't been set. Set this environment variable to a password that can be used for private key generation for certificate creation."
    exit 1
fi
MINIO=./minio
if test -f "$MINIO"; then
    echo "minio executable exists. No need to download"
else
    wget https://dl.min.io/server/minio/release/linux-amd64/minio
    chmod +x minio
fi

mkdir -p ./miniodata/data{1..8}
mkdir -p ./miniocert/CAs

# Certificate generation

# Create Open SSL config.
pushd miniocert
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

openssl genrsa -aes256 -passout env:CERTPASS -out private-pkcs8-key.key 2048
openssl rsa -in private-pkcs8-key.key -aes256  -passin env:CERTPASS -passout env:CERTPASS -out private.key
openssl req -new -x509 -nodes -days 730 -key private.key  -passin env:CERTPASS -out public.crt -config openssl.conf
popd

export MINIO_ROOT_USER=saurabh
export MINIO_ROOT_PASSWORD=SomePassword
export MINIO_SERVER_URL=https://$IP_ADDR:9000
export MINIO_CERT_PASSWD=$CERTPASS
./minio server ./miniodata/data{1...8} --console-address ":9001" --certs-dir ./miniocert
