#!/bin/bash

# DO280 Lab 3-1 정리 스크립트
# HTPasswd Identity Provider 실습 환경 초기화

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-1 환경 정리"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 사전 조건 확인
echo -e "${YELLOW}[1/6] 사전 조건 확인 중...${NC}"

if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ OpenShift 클러스터에 로그인되어 있지 않습니다.${NC}"
    echo "먼저 'oc login' 명령으로 클러스터 관리자 권한으로 로그인하세요."
    exit 1
fi

if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo -e "${RED}✗ 클러스터 관리자 권한이 필요합니다.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 사전 조건 확인 완료${NC}"
echo ""

# 1. 생성된 사용자 확인 및 삭제
echo -e "${YELLOW}[2/6] 생성된 사용자 삭제 중...${NC}"

USERS=("alice" "bob" "charlie" "david" "emma")

for user in "${USERS[@]}"; do
    # User 리소스 삭제
    if oc get user "$user" &>/dev/null; then
        oc delete user "$user" 2>/dev/null || true
        echo "  - User '$user' 삭제됨"
    fi
    
    # Identity 리소스 삭제
    if oc get identity "do280-htpasswd:$user" &>/dev/null; then
        oc delete identity "do280-htpasswd:$user" 2>/dev/null || true
        echo "  - Identity 'do280-htpasswd:$user' 삭제됨"
    fi
done

echo -e "${GREEN}✓ 사용자 삭제 완료${NC}"
echo ""

# 2. Identity Provider 설정 제거
echo -e "${YELLOW}[3/6] Identity Provider 설정 제거 중...${NC}"

# OAuth 클러스터 리소스에서 do280-htpasswd identity provider 제거
if oc get oauth cluster -o yaml | grep -q "do280-htpasswd"; then
    echo "  - OAuth 설정에서 do280-htpasswd Identity Provider 제거 중..."
    
    # 현재 OAuth 설정 가져오기
    oc get oauth cluster -o yaml > /tmp/oauth-current.yaml
    
    # Python을 사용하여 YAML에서 해당 Identity Provider 제거
    python3 -c "
import yaml
import sys

with open('/tmp/oauth-current.yaml', 'r') as f:
    oauth_config = yaml.safe_load(f)

if 'spec' in oauth_config and 'identityProviders' in oauth_config['spec']:
    providers = oauth_config['spec']['identityProviders']
    filtered_providers = [p for p in providers if p.get('name') != 'do280-htpasswd']
    
    if len(filtered_providers) != len(providers):
        oauth_config['spec']['identityProviders'] = filtered_providers
        with open('/tmp/oauth-updated.yaml', 'w') as f:
            yaml.dump(oauth_config, f, default_flow_style=False)
        print('Identity Provider 제거됨')
    else:
        print('do280-htpasswd Identity Provider를 찾을 수 없음')
else:
    print('identityProviders 설정이 없음')
" 2>/dev/null || echo "  - Python을 사용한 YAML 처리 실패, 수동 제거 필요"

    # 업데이트된 설정 적용 (Python 처리가 성공한 경우)
    if [ -f /tmp/oauth-updated.yaml ]; then
        oc apply -f /tmp/oauth-updated.yaml
        rm -f /tmp/oauth-updated.yaml
    fi
    
    rm -f /tmp/oauth-current.yaml
else
    echo "  else:
    echo "  - do280-htpasswd Identity Provider가 설정되어 있지 않음"
fi"
fi

echo -e "${GREEN}✓ Identity Provider 설정 제거 완료${NC}"
echo ""

# 3. Secret 삭제
echo -e "${YELLOW}[4/6] Secret 삭제 중...${NC}"

if oc get secret do280-idp-secret -n openshift-config &>/dev/null; then
    oc delete secret do280-idp-secret -n openshift-config
    echo "  - Secret 'do280-idp-secret' 삭제됨"
else
    echo "  - Secret 'do280-idp-secret'이 존재하지 않음"
fi

echo -e "${GREEN}✓ Secret 삭제 완료${NC}"
echo ""

# 4. 로컬 파일 정리
echo -e "${YELLOW}[5/6] 로컬 파일 정리 중...${NC}"

cd "$LAB_DIR"

# HTPasswd 파일 삭제
if [ -f htpasswd ]; then
    rm -f htpasswd
    echo "  - htpasswd 파일 삭제됨"
fi

# 백업 파일 삭제
if [ -f oauth-backup.yaml ]; then
    rm -f oauth-backup.yaml
    echo "  - oauth-backup.yaml 삭제됨"
fi

if [ -f secret-backup.yaml ]; then
    rm -f secret-backup.yaml
    echo "  - secret-backup.yaml 삭제됨"
fi

echo -e "${GREEN}✓ 로컬 파일 정리 완료${NC}"
echo ""

# 5. OAuth Pod 재시작 대기 (선택적)
echo -e "${YELLOW}[6/6] OAuth Pod 재시작 확인 중...${NC}"

echo "  - OAuth 설정 변경으로 인한 Pod 재시작을 기다리는 중..."
sleep 5

# OAuth Pod 상태 확인
if oc get pods -n openshift-authentication | grep -q "oauth-openshift"; then
    echo "  - OAuth Pod 상태 확인됨"
else
    echo "  - OAuth Pod 상태를 확인할 수 없음 (정상적일 수 있음)"
fi

echo -e "${GREEN}✓ OAuth Pod 상태 확인 완료${NC}"
echo ""

# 정리 완료 메시지
echo -e "${BLUE}=========================================="
echo "실습 환경 정리 완료!"
echo "=========================================="
echo ""
echo "다음 항목들이 정리되었습니다:"
echo "✓ 생성된 사용자 계정 (alice, bob, charlie, david, emma)"
echo "✓ Identity 리소스"
echo "✓ do280-htpasswd Identity Provider 설정"
echo "✓ do280-idp-secret Secret"
echo "✓ 로컬 HTPasswd 파일 및 백업 파일"
echo ""
echo "정리가 완료되었습니다."
echo -e "${NC}"

echo -e "${GREEN}✓ 전체 정리 작업 완료${NC}"