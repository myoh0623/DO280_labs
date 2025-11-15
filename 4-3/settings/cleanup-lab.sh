#!/bin/bash

# DO280 Lab 4-3 정리 스크립트
# 실습 환경 초기화

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 4-3 환경 정리"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Frontend 프로젝트 삭제
echo -e "${YELLOW}[1/2] Frontend 프로젝트 삭제 중...${NC}"
oc delete project frontend --wait=false 2>/dev/null || echo "Frontend 프로젝트가 이미 삭제되었거나 존재하지 않습니다."
echo -e "${GREEN}✓ Frontend 프로젝트 삭제 요청 완료${NC}"
echo ""

# 2. Backend 프로젝트 삭제
echo -e "${YELLOW}[2/2] Backend 프로젝트 삭제 중...${NC}"
oc delete project backend --wait=false 2>/dev/null || echo "Backend 프로젝트가 이미 삭제되었거나 존재하지 않습니다."
echo -e "${GREEN}✓ Backend 프로젝트 삭제 요청 완료${NC}"
echo ""

echo "=========================================="
echo -e "${GREEN}실습 환경 정리 완료!${NC}"
echo "=========================================="
echo ""
echo "다시 실습하려면 다음 명령어를 실행하세요:"
echo "  cd $LAB_DIR/settings"
echo "  ./setup-lab.sh"
echo ""
