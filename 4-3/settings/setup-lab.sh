#!/bin/bash

# DO280 Lab 4-3: Network Policies 구성 - 자동 설정 스크립트

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 4-3 - Network Policies 실습 환경 구성"
echo "=========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Backend 프로젝트 생성 및 배포
echo -e "${YELLOW}[1/5] Backend 프로젝트 생성 및 MySQL 배포 중...${NC}"
oc apply -f "$SCRIPT_DIR/backend-deployment.yaml"
echo -e "${GREEN}✓ Backend 프로젝트 및 MySQL 배포 완료${NC}"
echo ""

# 2. Frontend 프로젝트 생성 및 배포
echo -e "${YELLOW}[2/5] Frontend 프로젝트 생성 및 클라이언트 배포 중...${NC}"
oc apply -f "$SCRIPT_DIR/frontend-deployment.yaml"
echo -e "${GREEN}✓ Frontend 프로젝트 및 클라이언트 배포 완료${NC}"
echo ""

# 3. Backend MySQL Pod 준비 대기
echo -e "${YELLOW}[3/5] Backend MySQL Pod 준비 상태 확인 중...${NC}"
oc wait --for=condition=ready pod -l app=mysql -n backend --timeout=180s
echo -e "${GREEN}✓ MySQL Pod 준비 완료${NC}"
echo ""

# 4. deny-all 정책 적용
echo -e "${YELLOW}[4/5] Backend에 deny-all Network Policy 적용 중...${NC}"
sleep 5  # MySQL이 완전히 준비될 시간 제공
oc apply -f "$SCRIPT_DIR/backend-deny-all-policy.yaml"
echo -e "${GREEN}✓ deny-all Policy 적용 완료${NC}"
echo -e "${YELLOW}⚠️  이제 Frontend에서 Backend MySQL에 접근할 수 없습니다${NC}"
echo ""

# 5. Frontend Pod 상태 확인
echo -e "${YELLOW}[5/5] Frontend Pod 상태 확인 중...${NC}"
sleep 5
oc get pods -n frontend
echo ""

# 배포 상태 확인
echo "=========================================="
echo "배포된 리소스 확인"
echo "=========================================="
echo ""
echo "Backend 프로젝트:"
oc get all -n backend
echo ""
echo "Frontend 프로젝트:"
oc get all -n frontend
echo ""
echo "Network Policies:"
oc get networkpolicy -n backend
echo ""

echo "=========================================="
echo -e "${GREEN}실습 환경 구성 완료!${NC}"
echo "=========================================="
