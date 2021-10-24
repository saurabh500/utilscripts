# Utility script for launching Minio S3 deployment.

`minio.sh` contains a utility to launch a minio endpoint on Ubuntu 20.04. 
This utility might work on other Linux distributions but hasn't been tested. 

The utility does the following:

0. Downloads the minio binary in the same folder as the script.
1. Create multiple data folders for Minio to place the files.
2. Generate a self-signed certificate for MinIO to use and serve HTTPS requests.
3. Launches Minio with `Erasure Coding`

The script is not meant to be used for production. 
On relaunching the script
1. The data folders will not be recreated. 
2. The private key of the certificate will be recreated and certificate will be re-generated. 

## Configurability

The following environment variables can be set before script execution to override some behavior
1. `IP_ADDR`: The script tries to get the `eth0` interface IP address by default. However if the minio deployment should be bound to another interface or DNS name, set the IP_ADDR env var. This is also used in the certificate SAN.
2. `MINIO_ROOT_USER`: This env var can be set to a desired minio root user. Default is "minioadmin"
3. `MINIO_ROOT_PASSWORD`: This env var can be set to a desired root password for MinIO. If not set, then a random password is generated and used. The random password will be printed on console during script execution.
4. `MINIO_CERT_PASSWD`: This env var can be set to a desired password for protecting the private key of the certificate. If not set, then a random password is generated and used. The random password will be printed on console during script execution.

