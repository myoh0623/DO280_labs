#!/bin/bash

# DO280 Lab 6-1: ResourceQuota 설정 - 자동 설정 스크립트
# 프로젝트 자원 할당량 관리 실습 환경 구성

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 6-1 - ResourceQuota 실습 환경 구성"
echo "=========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. team-alpha 프로젝트 생성
echo -e "${YELLOW}[1/4] team-alpha 프로젝트 생성 중...${NC}"
oc apply -f "$SCRIPT_DIR/team-alpha.yaml"
echo -e "${GREEN}✓ team-alpha 프로젝트 및 테스트 애플리케이션 배포 완료${NC}"
echo ""

# 2. team-beta 프로젝트 생성
echo -e "${YELLOW}[2/4] team-beta 프로젝트 생성 중...${NC}"
oc apply -f "$SCRIPT_DIR/team-beta.yaml"
echo -e "${GREEN}✓ team-beta 프로젝트 및 테스트 애플리케이션 배포 완료${NC}"
echo ""

# 3. Pod 시작 대기
echo -e "${YELLOW}[3/4] Pod 준비 상태 확인 중...${NC}"
echo "  - team-alpha Pod 대기 중..."
oc wait --for=condition=ready pod -l app=test-app -n team-alpha --timeout=120s 2>/dev/null || echo "  ⚠ team-alpha Pod가 아직 준비되지 않았습니다"
echo "  - team-beta Pod 대기 중..."
oc wait --for=condition=ready pod -l app=test-app -n team-beta --timeout=120s 2>/dev/null || echo "  ⚠ team-beta Pod가 아직 준비되지 않았습니다"
echo -e "${GREEN}✓ Pod 준비 상태 확인 완료${NC}"
echo ""

# 4. 초기 상태 확인
echo -e "${YELLOW}[4/4] 초기 리소스 상태 확인 중...${NC}"
echo ""
echo "team-alpha 프로젝트:"
oc get all -n team-alpha
echo ""
echo "team-beta 프로젝트:"
oc get all -n team-beta
echo ""

# 완료 메시지
echo "=========================================="
echo -e "${GREEN}실습 환경 구성 완료!${NC}"
echo "=========================================="