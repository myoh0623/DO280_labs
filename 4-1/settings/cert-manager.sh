bin/bash

# SSL/TLS Certificate Generator Script
# This script generates a self-signed certificate and private key

echo "=========================================="
echo "SSL/TLS Certificate Generator"
echo "=========================================="
echo ""

# Ask for certificate details
read -p "Enter Common Name (e.g., webapp.domain1.example.com): " COMMON_NAME
read -p "Enter Organization Unit (e.g., IT): " ORG_UNIT
read -p "Enter Organization Name (e.g., Red Hat): " ORG_NAME
read -p "Enter Locality Name (e.g., California): " LOCALITY
read -p "Enter State/Province (e.g., NV): " STATE
read -p "Enter Country Code (e.g., US): " COUNTRY

echo ""
echo "Generating certificate with the following details:"
echo "  Common Name: $COMMON_NAME"
echo "  Organization Unit: $ORG_UNIT"
echo "  Organization: $ORG_NAME"
echo "  Locality: $LOCALITY"
echo "  State: $STATE"
echo "  Country: $COUNTRY"
echo ""

# Generate private key
openssl genrsa -out marketing.key 2048

# Generate certificate signing request (CSR)
openssl req -new -key marketing.key -out marketing.csr \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORG_NAME/OU=$ORG_UNIT/CN=$COMMON_NAME"

# Generate self-signed certificate
openssl x509 -req -days 365 -in marketing.csr -signkey marketing.key -out marketing.crt

echo ""
echo "=========================================="
echo "Certificate generation completed!"
echo "=========================================="
echo "Generated files:"
echo "  - marketing.key (Private Key)"
echo "  - marketing.crt (Certificate)"
echo "  - marketing.csr (Certificate Signing Request)"
echo ""
