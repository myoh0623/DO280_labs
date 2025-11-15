#!/bin/bash

# DO280 Lab 4-1: TLS로 외부 트래픽 보호 - 자동 설정 스크립트
# Edge Termination 실습 환경 구성

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 4-1 - Edge Termination 실습 환경 구성"
echo "=========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 프로젝트 생성
echo -e "${YELLOW}[1/5] 프로젝트 생성 중...${NC}"
oc new-project business --display-name="Business Marketing" --description="DO280 Lab 4-1" 2>/dev/null || oc project business
echo -e "${GREEN}✓ 프로젝트 생성 완료${NC}"
echo ""

# 2. 애플리케이션 배포
echo -e "${YELLOW}[2/5] Marketing 애플리케이션 배포 중...${NC}"
oc apply -f "$SCRIPT_DIR/marketing-deployment.yaml"
oc apply -f "$SCRIPT_DIR/marketing-service.yaml"
echo -e "${GREEN}✓ 애플리케이션 배포 완료${NC}"
echo ""

# 3. 비보안 Route 생성
echo -e "${YELLOW}[3/5] 비보안 HTTP Route 생성 중...${NC}"
oc apply -f "$SCRIPT_DIR/marketing-route-unsecured.yaml"
echo -e "${GREEN}✓ Route 생성 완료${NC}"
echo ""

# 4. 인증서 스크립트를 시스템 디렉토리로 이동 (시험 환경 시뮬레이션)
echo -e "${YELLOW}[4/5] 인증서 생성 스크립트 배치 중...${NC}"
sudo mkdir -p /opt/scripts
sudo mv "$SCRIPT_DIR/cert-manager.sh" /opt/scripts/
sudo chmod +x /opt/scripts/cert-manager.sh
echo -e "${GREEN}✓ 스크립트가 /opt/scripts/cert-manager.sh 로 이동됨${NC}"
echo -e "${GREEN}✓ find 명령어로 찾아서 사용하세요${NC}"
echo ""

# 5. Pod 시작 대기
echo -e "${YELLOW}[5/5] Pod 준비 상태 확인 중...${NC}"
oc wait --for=condition=ready pod -l app=marketing -n business --timeout=120s
echo -e "${GREEN}✓ Pod 준비 완료${NC}"
echo ""

echo "=========================================="
echo -e "${GREEN}실습 환경 구성 완료!${NC}"
echo "=========================================="
