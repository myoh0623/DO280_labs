#!/bin/bash

# DO280 Lab 8-1: Security Context Constraints (SCC) 실습 환경 구성

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 현재 스크립트의 디렉토리 경로 가져오기
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DO280 Lab 8-1: SCC 실습 환경 구성${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# production 프로젝트 생성
echo -e "${YELLOW}[1/3]${NC} production 프로젝트 생성 중..."
oc apply -f "${SCRIPT_DIR}/production-project.yaml"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} production 프로젝트 생성 완료"
else
    echo -e "${RED}✗${NC} production 프로젝트 생성 실패"
    exit 1
fi

echo ""

# Deployment가 실패하는 것 확인
echo -e "${YELLOW}[2/3]${NC} 기본 Deployment 상태 확인 중 (restricted SCC로 인한 실패 예상)..."
sleep 5

# Pod 상태 확인
POD_STATUS=$(oc get pods -n production -l app=root-app -o jsonpath='{.items[0].status.phase}' 2>/dev/null)

if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}⚠${NC} Pod가 Running 상태가 아닙니다 (예상된 동작)"
    echo -e "${YELLOW}ℹ${NC} Restricted SCC에서는 root 사용자로 실행할 수 없습니다"
else
    echo -e "${GREEN}✓${NC} Pod가 실행 중입니다"
fi

echo ""

# 현재 상태 확인
echo -e "${YELLOW}[3/3]${NC} 실습 환경 상태 확인..."
echo ""
echo -e "${BLUE}프로젝트:${NC}"
oc get project production
echo ""
echo -e "${BLUE}Deployment:${NC}"
oc get deployment -n production
echo ""
echo -e "${BLUE}Pods:${NC}"
oc get pods -n production
echo ""
echo -e "${BLUE}ServiceAccount (기본):${NC}"
oc get sa -n production
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}실습 환경 구성 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "다음 단계:"
echo -e "  cd /home/student/Desktop/DO280_labs/8-1"
echo -e "  README.md 파일을 참고하여 실습을 진행하세요"
echo ""
echo -e "${YELLOW}실습 과제:${NC}"
echo -e "  1. redhat-sa ServiceAccount 생성"
echo -e "  2. anyuid SCC를 redhat-sa에 부여"
echo -e "  3. Deployment에 redhat-sa 적용하여 root 실행 성공 확인"
echo ""
