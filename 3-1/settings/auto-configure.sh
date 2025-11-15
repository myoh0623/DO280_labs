#!/bin/bash

# DO280 Lab 3-1: HTPasswd Identity Provider 자동 구성 스크립트
# 전체 실습 과정을 자동으로 수행

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-1 - HTPasswd Identity Provider 자동 구성"
echo "=========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 사전 조건 확인
echo -e "${YELLOW}[1/6] 사전 조건 확인 중...${NC}"

if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ OpenShift 클러스터에 로그인되어 있지 않습니다.${NC}"
    exit 1
fi

if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo -e "${RED}✗ 클러스터 관리자 권한이 필요합니다.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 사전 조건 확인 완료${NC}"
echo ""

# 작업 디렉토리 이동
cd "$LAB_DIR"

# 1. HTPasswd 파일 생성
echo -e "${YELLOW}[2/6] HTPasswd 파일 생성 중...${NC}"

# 기존 파일 제거
rm -f htpasswd

# 사용자 계정 생성
htpasswd -c -B -b htpasswd alice alice@123
htpasswd -B -b htpasswd bob bob123
htpasswd -B -b htpasswd charlie charlie@123
htpasswd -B -b htpasswd david david@123
htpasswd -B -b htpasswd emma emma123

echo -e "${GREEN}✓ HTPasswd 파일 생성 완료${NC}"
echo "  - 생성된 사용자: alice, bob, charlie, david, emma"
echo ""

# 2. Secret 생성
echo -e "${YELLOW}[3/6] Secret 생성 중...${NC}"

# 기존 Secret 삭제 (있다면)
oc delete secret do280-idp-secret -n openshift-config 2>/dev/null || true

# 새 Secret 생성
oc create secret generic do280-idp-secret \
  --from-file=htpasswd=htpasswd -n openshift-config

echo -e "${GREEN}✓ Secret 생성 완료${NC}"
echo "  - Secret 이름: do280-idp-secret"
echo "  - Namespace: openshift-config"
echo ""

# 3. OAuth 설정 백업
echo -e "${YELLOW}[4/6] OAuth 설정 백업 중...${NC}"

oc get oauth cluster -o yaml > oauth-backup.yaml

echo -e "${GREEN}✓ OAuth 설정 백업 완료${NC}"
echo ""

# 4. Identity Provider 구성
echo -e "${YELLOW}[5/6] Identity Provider 구성 중...${NC}"

# 현재 OAuth 설정 가져오기
oc get oauth cluster -o yaml > /tmp/current-oauth.yaml

# Python을 사용하여 Identity Provider 추가
python3 -c "
import yaml
import sys

# 현재 OAuth 설정 로드
with open('/tmp/current-oauth.yaml', 'r') as f:
    oauth_config = yaml.safe_load(f)

# spec이 없으면 생성
if 'spec' not in oauth_config:
    oauth_config['spec'] = {}

# identityProviders가 없으면 생성
if 'identityProviders' not in oauth_config['spec']:
    oauth_config['spec']['identityProviders'] = []

# do280-htpasswd provider가 이미 있는지 확인
providers = oauth_config['spec']['identityProviders']
provider_exists = any(p.get('name') == 'do280-htpasswd' for p in providers)

if not provider_exists:
    # 새 Identity Provider 추가
    new_provider = {
        'name': 'do280-htpasswd',
        'mappingMethod': 'claim',
        'type': 'HTPasswd',
        'htpasswd': {
            'fileData': {
                'name': 'do280-idp-secret'
            }
        }
    }
    oauth_config['spec']['identityProviders'].append(new_provider)

# 업데이트된 설정 저장
with open('/tmp/updated-oauth.yaml', 'w') as f:
    yaml.dump(oauth_config, f, default_flow_style=False)

print('Identity Provider 구성 완료')
"

# 업데이트된 설정 적용
oc apply -f /tmp/updated-oauth.yaml

# 임시 파일 정리
rm -f /tmp/current-oauth.yaml /tmp/updated-oauth.yaml

echo -e "${GREEN}✓ Identity Provider 구성 완료${NC}"
echo "  - Provider 이름: do280-htpasswd"
echo "  - Mapping Method: claim"
echo "  - Type: HTPasswd"
echo ""

# 5. OAuth Pod 재시작 대기
echo -e "${YELLOW}[6/6] OAuth Pod 재시작 대기 중...${NC}"

echo "  - OAuth 설정 변경으로 인한 Pod 재시작을 기다리는 중..."
sleep 10

echo -e "${GREEN}✓ Identity Provider 구성 완료${NC}"
echo ""

# 완료 메시지 및 검증 안내
echo -e "${BLUE}=========================================="
echo "HTPasswd Identity Provider 구성 완료!"
echo "=========================================="
echo ""
echo "구성된 내용:"
echo "✓ Identity Provider: do280-htpasswd"
echo "✓ Secret: do280-idp-secret (openshift-config namespace)"
echo "✓ 생성된 사용자 계정:"
echo "  - alice (비밀번호: alice@123)"
echo "  - bob (비밀번호: bob123)"
echo "  - charlie (비밀번호: charlie@123)"
echo "  - david (비밀번호: david@123)"
echo "  - emma (비밀번호: emma123)"
echo ""
echo "검증 방법:"
echo "1. oc get oauth cluster -o yaml | grep do280-htpasswd"
echo "2. oc login -u alice -p alice@123"
echo "3. oc whoami"
echo ""
echo "실습 완료 후 './settings/cleanup-lab.sh'를 실행하여 환경을 정리하세요."
echo -e "${NC}"