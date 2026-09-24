#!/usr/bin/env bash
################################
# Developer: Liad Binyamin
# Purpose: Set up and trust the Outline certificate in the Debian/Ubuntu system trust store
# Version: 0.0.2
# Date: 23.9.26
set -o errexit
set -o pipefail
set -o nounset
################################


SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CERT_FILE="$SCRIPT_DIR/../nginx/certs/outline.liadev.crt"
DOMAIN="outline.liadev"
IP="100.104.250.14"


check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo ./setup-outline-debian.sh"
    exit 1
  fi
}

# Make sure the certificate file exists
check_cert_file() {
  if [ ! -f "$CERT_FILE" ]; then
    echo "Certificate not found: $CERT_FILE"
    exit 1
  fi
}

# Copy the certificate to the trust folder and update the system trust store
install_cert() {
  cp "$CERT_FILE" /usr/local/share/ca-certificates/outline.liadev.crt
  update-ca-certificates
  echo "Certificate installed and trusted in the system trust store."
}

# Add the DNS record, only if it doesn't already exist
add_dns_record() {
  if grep -q "$DOMAIN" /etc/hosts; then
    echo "DNS record for $DOMAIN already exists in /etc/hosts, skipping."
  else
    echo "$IP $DOMAIN" >> /etc/hosts
    echo "Added DNS record: $IP $DOMAIN"
  fi
}

main() {
  check_root
  check_cert_file
  install_cert
  add_dns_record
}

main