#!/bin/bash -e

ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

if [[ -z "${IP_ADDR}" ]]; then
    echo "IP_ADDR environment variable hasn't been set. Using $ip4 to create MinIO. To Use a different IP address to expose MinIO, set IP_ADDR env var"
    IP_ADDR=$ip4
fi

generate_random_password() {
     random=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c7)
     upper=$(tr -dc 'A-Z' </dev/urandom | head -c1)
     lower=$(tr -dc 'a-z' </dev/urandom | head -c1)
     digit=$(tr -dc '0-9' </dev/urandom | head -c1)
     echo $(echo $random$upper$lower$digit | fold -w1 | shuf | tr -d '\n')
}

if [[ -z "${CERTPASS}" ]]; then
    CERTPASS="$(generate_random_password)"
    echo "CERTPASS Environment var does not exist. Generating a random password $CERTPASS."
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

openssl genrsa -aes256 -passout pass:$CERTPASS -out private-pkcs8-key.key 2048
openssl rsa -in private-pkcs8-key.key -aes256  -passin pass:$CERTPASS -passout pass:$CERTPASS -out private.key
openssl req -new -x509 -nodes -days 730 -key private.key -passin pass:$CERTPASS -out public.crt -config openssl.conf
popd

export MINIO_ROOT_USER=saurabh
export MINIO_ROOT_PASSWORD=SomePassword
export MINIO_SERVER_URL=https://$IP_ADDR:9000
export MINIO_CERT_PASSWD=$CERTPASS
./minio server ./miniodata/data{1...8} --console-address ":9001" --certs-dir ./miniocert
