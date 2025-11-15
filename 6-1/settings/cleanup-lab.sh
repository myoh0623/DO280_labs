#!/bin/bash

# DO280 Lab 6-1 정리 스크립트
# 실습 환경 초기화

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 6-1 환경 정리"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. team-alpha 프로젝트 삭제
echo -e "${YELLOW}[1/2] team-alpha 프로젝트 삭제 중...${NC}"
oc delete project team-alpha --wait=false 2>/dev/null || echo "team-alpha 프로젝트가 이미 삭제되었거나 존재하지 않습니다."
echo -e "${GREEN}✓ team-alpha 프로젝트 삭제 요청 완료${NC}"
echo ""

# 2. team-beta 프로젝트 삭제
echo -e "${YELLOW}[2/2] team-beta 프로젝트 삭제 중...${NC}"
oc delete project team-beta --wait=false 2>/dev/null || echo "team-beta 프로젝트가 이미 삭제되었거나 존재하지 않습니다."
echo -e "${GREEN}✓ team-beta 프로젝트 삭제 요청 완료${NC}"
echo ""

echo "=========================================="
echo -e "${GREEN}실습 환경 정리 완료!${NC}"
echo "=========================================="
echo ""
echo "다시 실습하려면 다음 명령어를 실행하세요:"
echo "  cd $LAB_DIR/settings"
echo "  ./setup-lab.sh"
echo ""
