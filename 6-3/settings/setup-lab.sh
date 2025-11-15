#!/bin/bash

# DO280 Lab 6-3: LimitRange 실습 환경 구성 스크립트

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 현재 스크립트의 디렉토리 경로 가져오기
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DO280 Lab 6-3: LimitRange 실습 환경 구성${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# bluebook 프로젝트 생성
echo -e "${YELLOW}[1/3]${NC} bluebook 프로젝트 생성 중..."
oc apply -f "${SCRIPT_DIR}/bluebook-project.yaml"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} bluebook 프로젝트 생성 완료"
else
    echo -e "${RED}✗${NC} bluebook 프로젝트 생성 실패"
    exit 1
fi

echo ""

# Pod가 Ready 상태가 될 때까지 대기
echo -e "${YELLOW}[2/3]${NC} bluebook 프로젝트의 Pod가 Ready 상태가 될 때까지 대기 중..."
oc wait --for=condition=ready pod -l app=test-app -n bluebook --timeout=120s

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Pod가 Ready 상태입니다"
else
    echo -e "${YELLOW}⚠${NC} Pod가 아직 Ready 상태가 아닙니다 (계속 진행)"
fi

echo ""

# 현재 상태 확인
echo -e "${YELLOW}[3/3]${NC} 실습 환경 상태 확인..."
echo ""
echo -e "${BLUE}프로젝트:${NC}"
oc get project bluebook
echo ""
echo -e "${BLUE}Deployment:${NC}"
oc get deployment -n bluebook
echo ""
echo -e "${BLUE}Pods:${NC}"
oc get pods -n bluebook
echo ""
echo -e "${BLUE}LimitRange (현재 없음):${NC}"
oc get limitrange -n bluebook
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}실습 환경 구성 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
