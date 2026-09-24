#!/usr/bin/env bash
################################
# Developer: Liad Binyamin
# Purpose: Set up and trust the Outline certificate in the macOS System keychain
# Version: 0.0.4
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
    echo "Please run with sudo"
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

# Add the certificate to the System keychain and mark it as trusted
install_cert() {
  security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CERT_FILE"
  echo "Certificate installed and trusted in the System keychain."
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

# Clear the macOS DNS cache so the new record works right away
flush_dns_cache() {
  dscacheutil -flushcache
  killall -HUP mDNSResponder
  echo "DNS cache cleared."
}

main() {
  check_root
  check_cert_file
  install_cert
  add_dns_record
  flush_dns_cache
}

main