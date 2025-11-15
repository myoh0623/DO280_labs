#!/bin/bash

# DO280 Lab 6-3: LimitRange 실습 환경 정리 스크립트

# 색상 정의
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DO280 Lab 6-3: LimitRange 실습 환경 정리${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# bluebook 프로젝트 삭제
echo -e "${YELLOW}[1/1]${NC} bluebook 프로젝트 삭제 중..."
oc delete project bluebook

if [ $? -eq 0 ]; then
    echo -e "${RED}✓${NC} bluebook 프로젝트 삭제 완료"
else
    echo -e "${YELLOW}⚠${NC} bluebook 프로젝트가 존재하지 않거나 이미 삭제되었습니다"
fi

echo ""
echo -e "${RED}========================================${NC}"
echo -e "${RED}실습 환경 정리 완료!${NC}"
echo -e "${RED}========================================${NC}"
