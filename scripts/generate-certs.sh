#!/usr/bin/env bash
################################
# Developer: Liad Binyamin
# Purpose: Create self-signed SSL certificate for Outline Wiki
# Version: 0.0.2
# Date: 23.9.26
set -o errexit
set -o pipefail
set -o nounset
################################


DOMAIN="outline.liadev"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CERT_DIR="$SCRIPT_DIR/../nginx/certs"
DAYS="3650"

openssl req -x509 -nodes -newkey rsa:2048 \
  -days "$DAYS" \
  -keyout "$CERT_DIR/outline.liadev.key" \
  -out "$CERT_DIR/outline.liadev.crt" \
  -subj "/CN=$DOMAIN" \
  -addext "subjectAltName=DNS:*.$DOMAIN,DNS:outline.$DOMAIN"

chmod 600 "$CERT_DIR/outline.liadev.key"  

echo "Certificate created for $DOMAIN (valid for $DAYS days)"