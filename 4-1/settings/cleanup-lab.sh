#!/bin/bash

# DO280 Lab 4-1 정리 스크립트
# 실습 환경 초기화

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 4-1 환경 정리"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. 프로젝트 삭제
echo -e "${YELLOW}[1/3] 프로젝트 삭제 중...${NC}"
oc delete project business --wait=false 2>/dev/null || echo "프로젝트가 이미 삭제되었거나 존재하지 않습니다."
echo -e "${GREEN}✓ 프로젝트 삭제 요청 완료${NC}"
echo ""

# 2. 인증서 파일 삭제 (실습 디렉토리에서)
echo -e "${YELLOW}[2/3] 생성된 인증서 파일 삭제 중...${NC}"
rm -f "$LAB_DIR"/*.crt "$LAB_DIR"/*.key "$LAB_DIR"/*.csr
rm -f "$LAB_DIR"/cert-manager.sh
echo -e "${GREEN}✓ 인증서 파일 삭제 완료${NC}"
echo ""

# 3. 스크립트 파일 정리
echo -e "${YELLOW}[3/4] 시스템 디렉토리 정리 중...${NC}"
sudo rm -f /opt/scripts/cert-manager.sh 2>/dev/null || true
echo -e "${GREEN}✓ /opt/scripts 정리 완료${NC}"
echo ""

# 4. cert-manager.sh를 settings로 복원 (재실습 대비)
echo -e "${YELLOW}[4/4] 실습 파일 복원 중...${NC}"
if [ ! -f "$SCRIPT_DIR/cert-manager.sh" ]; then
    cat > "$SCRIPT_DIR/cert-manager.sh" << 'EOF'
#!/bin/bash

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
EOF
    chmod +x "$SCRIPT_DIR/cert-manager.sh"
    echo -e "${GREEN}✓ cert-manager.sh 복원 완료${NC}"
else
    echo -e "${GREEN}✓ cert-manager.sh 이미 존재함${NC}"
fi
echo ""

echo "=========================================="
echo -e "${GREEN}실습 환경 정리 완료!${NC}"
echo "=========================================="
echo ""
echo "다시 실습하려면 다음 명령어를 실행하세요:"
echo "  cd $LAB_DIR/settings"
echo "  ./setup-lab.sh"
echo ""
