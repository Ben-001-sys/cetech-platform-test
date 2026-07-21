#!/usr/bin/env bash set -Eeuo pipefail repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" cert_dir="${repo_root}/environments/local/certs" mkdir -p "${cert_dir}" chmod 0700 "${cert_dir}" if [[ -e "${cert_dir}/cetech-local-ca.key" ]]; then echo "Certificate authority already exists; refusing overwrite." >&2 exit 1 fi openssl genrsa \ -out "${cert_dir}/cetech-local-ca.key" \ 4096 openssl req \ -x509 \ -new \ -nodes \ -key "${cert_dir}/cetech-local-ca.key" \ -sha256 \ -days 3650 \ -out "${cert_dir}/cetech-local-ca.crt" \ -subj "/C=GH/O=CETECH/OU=Local Development/CN=CETECH Local Development CA" openssl genrsa \ -out "${cert_dir}/cetech.test.key" \ 3072 cat > "${cert_dir}/cetech.test.cnf" <<'EOF' [req] default_bits = 3072 prompt = no default_md = sha256 distinguished_name = dn req_extensions = req_ext [dn] C = GH O = CETECH OU = Local Development CN = cetech.test [req_ext] subjectAltName = @alt_names [alt_names] DNS.1 = cetech.test DNS.2 = www.cetech.test DNS.3 = main.cetech.test DNS.4 = gh.cetech.test DNS.5 = en.cetech.test DNS.6 = mailpit.cetech.test DNS.7 = traefik.cetech.test EOF openssl req \ -new \ -key "${cert_dir}/cetech.test.key" \ -out "${cert_dir}/cetech.test.csr" \ -config "${cert_dir}/cetech.test.cnf" cat > "${cert_dir}/cetech.test.ext" <<'EOF' authorityKeyIdentifier=keyid,issuer basicConstraints=CA:FALSE keyUsage=digitalSignature,keyEncipherment extendedKeyUsage=serverAuth subjectAltName=@alt_names [alt_names] DNS.1=cetech.test DNS.2=www.cetech.test DNS.3=main.cetech.test DNS.4=gh.cetech.test DNS.5=en.cetech.test DNS.6=mailpit.cetech.test DNS.7=traefik.cetech.test EOF openssl x509 \ -req \ -in "${cert_dir}/cetech.test.csr" \ -CA "${cert_dir}/cetech-local-ca.crt" \ -CAkey "${cert_dir}/cetech-local-ca.key" \ -CAcreateserial \ -out "${cert_dir}/cetech.test.crt" \ -days 825 \ -sha256 \ -extfile "${cert_dir}/cetech.test.ext" chmod 0600 \ "${cert_dir}/cetech-local-ca.key" \ "${cert_dir}/cetech.test.key" chmod 0644 \ "${cert_dir}/cetech-local-ca.crt" \ "${cert_dir}/cetech.test.crt" openssl verify \ -CAfile "${cert_dir}/cetech-local-ca.crt" \ "${cert_dir}/cetech.test.crt" openssl x509 \ -in "${cert_dir}/cetech.test.crt" \ -noout \ -subject \ -issuer \ -dates \ -ext subjectAltName#!/usr/bin/env bash

set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cert_dir="${repo_root}/environments/local/certs"

mkdir -p "${cert_dir}"
chmod 0700 "${cert_dir}"

if [[ -e "${cert_dir}/cetech-local-ca.key" ]]; then
    echo "Certificate authority already exists; refusing overwrite." >&2
    exit 1
fi


#######################################
# Generate Local Certificate Authority
#######################################

openssl genrsa \
    -out "${cert_dir}/cetech-local-ca.key" \
    4096


openssl req \
    -x509 \
    -new \
    -nodes \
    -key "${cert_dir}/cetech-local-ca.key" \
    -sha256 \
    -days 3650 \
    -out "${cert_dir}/cetech-local-ca.crt" \
    -subj "/C=GH/O=CETECH/OU=Local Development/CN=CETECH Local Development CA"


#######################################
# Generate cetech.test private key
#######################################

openssl genrsa \
    -out "${cert_dir}/cetech.test.key" \
    3072


#######################################
# Certificate signing request config
#######################################

cat > "${cert_dir}/cetech.test.cnf" <<'EOF'
[req]
default_bits = 3072
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = GH
O = CETECH
OU = Local Development
CN = cetech.test

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = cetech.test
DNS.2 = www.cetech.test
DNS.3 = main.cetech.test
DNS.4 = gh.cetech.test
DNS.5 = en.cetech.test
DNS.6 = mailpit.cetech.test
DNS.7 = traefik.cetech.test
EOF


#######################################
# Generate CSR
#######################################

openssl req \
    -new \
    -key "${cert_dir}/cetech.test.key" \
    -out "${cert_dir}/cetech.test.csr" \
    -config "${cert_dir}/cetech.test.cnf"


#######################################
# Certificate extensions
#######################################

cat > "${cert_dir}/cetech.test.ext" <<'EOF'
authorityKeyIdentifier=keyid,issuer

basicConstraints=CA:FALSE

keyUsage=digitalSignature,keyEncipherment

extendedKeyUsage=serverAuth

subjectAltName=@alt_names

[alt_names]
DNS.1=cetech.test
DNS.2=www.cetech.test
DNS.3=main.cetech.test
DNS.4=gh.cetech.test
DNS.5=en.cetech.test
DNS.6=mailpit.cetech.test
DNS.7=traefik.cetech.test
EOF


#######################################
# Sign certificate with local CA
#######################################

openssl x509 \
    -req \
    -in "${cert_dir}/cetech.test.csr" \
    -CA "${cert_dir}/cetech-local-ca.crt" \
    -CAkey "${cert_dir}/cetech-local-ca.key" \
    -CAcreateserial \
    -out "${cert_dir}/cetech.test.crt" \
    -days 825 \
    -sha256 \
    -extfile "${cert_dir}/cetech.test.ext"


#######################################
# Permissions
#######################################

chmod 0600 \
    "${cert_dir}/cetech-local-ca.key" \
    "${cert_dir}/cetech.test.key"


chmod 0644 \
    "${cert_dir}/cetech-local-ca.crt" \
    "${cert_dir}/cetech.test.crt"


#######################################
# Verification
#######################################

openssl verify \
    -CAfile "${cert_dir}/cetech-local-ca.crt" \
    "${cert_dir}/cetech.test.crt"


#######################################
# Certificate information
#######################################

openssl x509 \
    -in "${cert_dir}/cetech.test.crt" \
    -noout \
    -subject \
    -issuer \
    -dates \
    -ext subjectAltName


echo "Local CETECH certificates generated successfully."
echo "Certificate directory:"
echo "${cert_dir}"