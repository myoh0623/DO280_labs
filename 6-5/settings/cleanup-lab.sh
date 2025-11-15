#!/bin/bash

# DO280 Lab 6-5: Project Template 실습 환경 정리 스크립트
# 클러스터 전역 설정을 원상복구합니다

# 색상 정의
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 현재 스크립트의 디렉토리 경로 가져오기
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DO280 Lab 6-5: Project Template 실습 환경 정리${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}⚠ 경고: 이 스크립트는 클러스터 전역 Project Template 설정을 제거합니다${NC}"
echo ""
read -p "계속하시겠습니까? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}작업이 취소되었습니다${NC}"
    exit 0
fi

echo ""

# Cluster 설정에서 Template 제거
echo -e "${YELLOW}[1/3]${NC} Cluster 설정에서 Project Template 제거 중..."

oc patch projects.config.openshift.io/cluster --type=json -p '[
  {
    "op": "remove",
    "path": "/spec/projectRequestTemplate"
  }
]' 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Cluster 설정 복구 완료"
else
    echo -e "${YELLOW}⚠${NC} Cluster 설정 복구 실패 또는 이미 제거됨"
fi

echo ""

# openshift-config에서 Template 삭제
echo -e "${YELLOW}[2/3]${NC} openshift-config에서 Project Template 삭제 중..."
oc delete template project-request -n openshift-config 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${RED}✓${NC} Template 삭제 완료"
else
    echo -e "${YELLOW}⚠${NC} Template이 존재하지 않거나 이미 삭제되었습니다"
fi

echo ""

# 백업 파일 정리 (선택사항)
echo -e "${YELLOW}[3/3]${NC} 생성된 파일 정리..."
rm -f "${SCRIPT_DIR}/project-template.yaml" 2>/dev/null
echo -e "${GREEN}✓${NC} project-template.yaml 삭제"

if [ -f "${SCRIPT_DIR}/cluster-config-backup.yaml" ]; then
    echo -e "${BLUE}ℹ${NC} 백업 파일 유지: ${SCRIPT_DIR}/cluster-config-backup.yaml"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}API Server 재시작 대기 중...${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}⏳ OpenShift API Server가 재시작됩니다 (약 2-3분 소요)${NC}"
echo -e "${YELLOW}⏳ 아래 명령으로 재시작 상태를 확인할 수 있습니다:${NC}"
echo ""
echo -e "  watch oc get clusteroperators"
echo ""

echo -e "${RED}========================================${NC}"
echo -e "${RED}실습 환경 정리 완료!${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "참고:"
echo -e "  - 실습 중 생성한 테스트 프로젝트는 수동으로 삭제하세요"
echo -e "  - 예: oc delete project test-project sample-project"
echo ""
