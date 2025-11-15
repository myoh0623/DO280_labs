#!/bin/bash

# DO280 Lab 3-1: Identity Provider - HTPasswd 실습 환경 설정 스크립트
# HTPasswd Identity Provider 구성을 위한 초기 환경 준비

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-1 - HTPasswd Identity Provider 실습 환경 구성"
echo "=========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. 사전 조건 확인
echo -e "${YELLOW}[1/4] 사전 조건 확인 중...${NC}"

# 클러스터 접근 확인
if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ OpenShift 클러스터에 로그인되어 있지 않습니다.${NC}"
    echo "먼저 'oc login' 명령으로 클러스터 관리자 권한으로 로그인하세요."
    exit 1
fi

# 클러스터 관리자 권한 확인
if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo -e "${RED}✗ 클러스터 관리자 권한이 필요합니다.${NC}"
    echo "cluster-admin 권한을 가진 사용자로 로그인하세요."
    exit 1
fi

echo -e "${GREEN}✓ 사전 조건 확인 완료${NC}"
echo "  - 현재 사용자: $(oc whoami)"
echo ""

# 2. 기존 HTPasswd 설정 확인 및 백업
echo -e "${YELLOW}[2/4] 기존 설정 확인 및 백업 중...${NC}"

# 기존 OAuth 설정 백업
oc get oauth cluster -o yaml > "$LAB_DIR/oauth-backup.yaml" 2>/dev/null || true

# 기존 HTPasswd secret 확인
if oc get secret do280-idp-secret -n openshift-config &>/dev/null; then
    echo -e "${YELLOW}⚠ 기존 do280-idp-secret이 존재합니다. 백업 중...${NC}"
    oc get secret do280-idp-secret -n openshift-config -o yaml > "$LAB_DIR/secret-backup.yaml"
fi

echo -e "${GREEN}✓ 기존 설정 백업 완료${NC}"
echo ""

# 3. 작업 디렉토리 설정
echo -e "${YELLOW}[3/4] 작업 디렉토리 설정 중...${NC}"

cd "$LAB_DIR"

# 기존 HTPasswd 파일이 있다면 제거
rm -f htpasswd

echo -e "${GREEN}✓ 작업 디렉토리 설정 완료${NC}"
echo "  - 작업 디렉토리: $LAB_DIR"
echo ""

# 4. 실습 안내 메시지
echo -e "${YELLOW}[4/4] 실습 안내${NC}"
echo -e "${BLUE}=========================================="
echo "실습 준비가 완료되었습니다!"
echo "=========================================="
echo ""
echo "다음 단계를 수행하세요:"
echo ""
echo "1. HTPasswd 파일 생성:"
echo "   htpasswd -c -B -b htpasswd alice alice@123"
echo "   htpasswd -B -b htpasswd bob bob123"
echo "   htpasswd -B -b htpasswd charlie charlie@123"
echo "   htpasswd -B -b htpasswd david david@123"
echo "   htpasswd -B -b htpasswd emma emma123"
echo ""
echo "2. Secret 생성:"
echo "   oc create secret generic do280-idp-secret \\"
echo "     --from-file=htpasswd=htpasswd -n openshift-config"
echo ""
echo "3. Identity Provider 구성:"
echo "   oc edit oauth cluster"
echo ""
echo "4. 사용자 로그인 테스트:"
echo "   oc login -u alice -p alice@123"
echo ""
echo "실습 완료 후 './settings/cleanup-lab.sh'를 실행하여 환경을 정리하세요."
echo -e "${NC}"

echo -e "${GREEN}✓ 실습 환경 설정 완료${NC}"