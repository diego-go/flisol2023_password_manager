#!/bin/bash

echo "## Creating bitwarden directory ##"
mkdir /opt/bitwarden

echo "## HTTPS cert ##"

echo "## Create a CA key (your own little on-premise Certificate Authority) ##"
printf "\n"
openssl genpkey -algorithm RSA -aes128 -out private-ca.key -outform PEM -pkeyopt rsa_keygen_bits:2048

if [ $? -ne 0 ] ; then
   echo "ERROR: Failed to generate KEY"
   exit 1
fi

echo "## Create a CA certificate ##"
echo "## Feel free to modify the common name to identify the cert ##"
printf "\n"
openssl req -x509 -new -nodes -sha256 -days 3650 -key private-ca.key -out self-signed-ca-cert.crt

printf "\n"
echo "## Create bitwarden key ##"
openssl genpkey -algorithm RSA -out bitwarden.key -outform PEM -pkeyopt rsa_keygen_bits:2048

printf "\n"
echo "## Create certificate request, set common name with IP address of your VM ##"
printf "\n"
ip addr | grep -Po '(?!(inet 127.\d.\d.1))(inet \K(\d{1,3}\.){3}\d{1,3})'
bitwarden_ip=$(ip addr | grep -Po '(?!(inet 127.\d.\d.1))(inet \K(\d{1,3}\.){3}\d{1,3})' | head -n1)

printf "\n"
openssl req -new -key bitwarden.key -out bitwarden.csr

printf "\n"
echo "## Create a text file bitwarden.ext with the following content, change the domain names to your setup."

printf "\n"
printf "authorityKeyIdentifier=keyid,issuer\nbasicConstraints=CA:FALSE\nkeyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment\nextendedKeyUsage = serverAuth\nsubjectAltName = @alt_names\n\n[alt_names]\nIP.1 = $bitwarden_ip\n" > bitwarden.ext

printf "\n"
# https://github.com/dani-garcia/vaultwarden/wiki/Private-CA-and-self-signed-certs-that-work-with-Chrome


echo "## Create the bitwarden certificate, signed from the root CA"
printf "\n"
openssl x509 -req -in bitwarden.csr -CA self-signed-ca-cert.crt -CAkey private-ca.key -CAcreateserial -out bitwarden.crt -days 365 -sha256 -extfile bitwarden.ext

mv bitwarden.crt bitwarden.key /etc/ssl/certs/

docker run -d --name bitwarden --restart unless-stopped -v /opt/bitwarden/:/data/ -v /etc/ssl/certs/:/ssl/ -e ROCKET_TLS='{certs="/ssl/bitwarden.crt",key="/ssl/bitwarden.key"}' -p 443:80 bitwardenrs/server