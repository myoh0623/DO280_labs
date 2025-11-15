#!/bin/bash

# DO280 Lab 6-5: Project Template 실습 환경 구성 스크립트
# 주의: 이 스크립트는 클러스터 전역 설정을 변경하므로 신중하게 실행하세요!

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 현재 스크립트의 디렉토리 경로 가져오기
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DO280 Lab 6-5: Project Template 실습 환경 구성${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}⚠ 경고: 이 스크립트는 클러스터 전역 Project Template을 설정합니다${NC}"
echo -e "${YELLOW}⚠ 실습 후 반드시 cleanup-lab.sh를 실행하여 원상복구하세요${NC}"
echo ""
read -p "계속하시겠습니까? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}작업이 취소되었습니다${NC}"
    exit 0
fi

echo ""

# 현재 Template 백업
echo -e "${YELLOW}[1/5]${NC} 기존 Project Template 설정 백업 중..."
oc get projects.config.openshift.io/cluster -o yaml > "${SCRIPT_DIR}/cluster-config-backup.yaml" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} 백업 완료: ${SCRIPT_DIR}/cluster-config-backup.yaml"
else
    echo -e "${YELLOW}⚠${NC} 백업 실패 (계속 진행)"
fi

echo ""

# Bootstrap Template 생성
echo -e "${YELLOW}[2/5]${NC} Bootstrap Project Template 생성 중..."
oc adm create-bootstrap-project-template -o yaml > "${SCRIPT_DIR}/project-template.yaml"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Bootstrap Template 생성 완료"
else
    echo -e "${RED}✗${NC} Bootstrap Template 생성 실패"
    exit 1
fi

echo ""

# LimitRange를 Template에 추가
echo -e "${YELLOW}[3/5]${NC} LimitRange를 Template에 추가 중..."

# YAML 파일에 LimitRange 객체 추가
cat >> "${SCRIPT_DIR}/project-template.yaml" <<'EOF'
- apiVersion: v1
  kind: LimitRange
  metadata:
    name: ${PROJECT_NAME}-limits
    namespace: ${PROJECT_NAME}
  spec:
    limits:
    - type: Container
      min:
        memory: "128Mi"
      max:
        memory: "256Mi"
      default:
        memory: "256Mi"
      defaultRequest:
        memory: "256Mi"
EOF

echo -e "${GREEN}✓${NC} LimitRange 추가 완료"
echo ""

# Template을 openshift-config에 생성
echo -e "${YELLOW}[4/5]${NC} Project Template을 openshift-config 네임스페이스에 등록 중..."
oc create -f "${SCRIPT_DIR}/project-template.yaml" -n openshift-config 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Template 등록 완료"
else
    echo -e "${YELLOW}⚠${NC} Template이 이미 존재합니다 (기존 것 사용)"
fi

echo ""

# Cluster 설정에 Template 적용
echo -e "${YELLOW}[5/5]${NC} Cluster 설정에 Template 적용 중..."

oc patch projects.config.openshift.io/cluster --type=merge -p '
{
  "spec": {
    "projectRequestTemplate": {
      "name": "project-request"
    }
  }
}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Cluster 설정 적용 완료"
else
    echo -e "${RED}✗${NC} Cluster 설정 적용 실패"
    exit 1
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
echo -e "${YELLOW}⏳ kube-apiserver와 openshift-apiserver의 PROGRESSING이 False가 되면 완료입니다${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}실습 환경 구성 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "다음 단계:"
echo -e "  1. API Server 재시작 완료까지 대기 (2-3분)"
echo -e "  2. cd /home/student/Desktop/DO280_labs/6-5"
echo -e "  3. README.md 파일을 참고하여 실습 진행"
echo ""
echo -e "${RED}반드시!!!!!!! 실습 완료 후 반드시 cleanup-lab.sh 실행!${NC}"
echo ""
