#!/bin/bash

# DO280 Lab 3-5 정리 스크립트
# 프로젝트별 권한 관리 실습 환경 초기화

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.2 환경 정리"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 사전 조건 확인
echo -e "${YELLOW}[1/5] 사전 조건 확인 중...${NC}"

if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ OpenShift 클러스터에 로그인되어 있지 않습니다.${NC}"
    echo "먼저 'oc login' 명령으로 클러스터 관리자 권한으로 로그인하세요."
    exit 1
fi

# emma로 전환 (프로젝트 삭제를 위한 관리자 권한 필요)
CURRENT_USER=$(oc whoami)
if [[ "$CURRENT_USER" != "emma" ]]; then
    echo "  - emma 사용자로 전환 중... (프로젝트 삭제를 위한 관리자 권한 필요)"
    if ! oc login -u emma -p emma123 &>/dev/null; then
        echo -e "${RED}✗ emma 사용자로 로그인할 수 없습니다.${NC}"
        exit 1
    fi
fi

if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo -e "${RED}✗ 클러스터 관리자 권한이 필요합니다.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 사전 조건 확인 완료${NC}"
echo "  - 현재 사용자: $(oc whoami)"
echo ""

# 1. 실습용 프로젝트 삭제
echo -e "${YELLOW}[2/5] 실습용 프로젝트 삭제 중...${NC}"

TARGET_PROJECTS=("team-alpha" "team-beta" "finance-apps" "it-automation")

for project in "${TARGET_PROJECTS[@]}"; do
    if oc get project "$project" &>/dev/null; then
        echo "  - 프로젝트 '$project' 삭제 중..."
        oc delete project "$project" --wait=false 2>/dev/null || true
        echo "  ✓ 프로젝트 '$project' 삭제 요청함"
    else
        echo "  - 프로젝트 '$project'이 이미 삭제되었거나 존재하지 않음"
    fi
done

echo -e "${GREEN}✓ 프로젝트 삭제 완료${NC}"
echo "  - 프로젝트 삭제는 백그라운드에서 진행됩니다."
echo ""

# 2. 사용자별 프로젝트 권한 정리 (프로젝트가 삭제되면 자동으로 정리되지만 확인)
echo -e "${YELLOW}[3/5] 사용자별 프로젝트 권한 확인 중...${NC}"

USERS=("alice" "charlie" "david")

echo "  - 남아있는 프로젝트별 권한 확인:"
for user in "${USERS[@]}"; do
    echo "    $user 사용자의 권한:"
    
    # 현재 사용자가 가진 rolebinding 확인
    PROJECT_BINDINGS=$(oc get rolebindings --all-namespaces | grep "$user" | wc -l)
    if [ "$PROJECT_BINDINGS" -gt 0 ]; then
        echo "      - 남아있는 프로젝트 권한: $PROJECT_BINDINGS개"
        oc get rolebindings --all-namespaces | grep "$user" | head -3
    else
        echo "      - 프로젝트별 권한 없음"
    fi
done

echo -e "${GREEN}✓ 사용자별 프로젝트 권한 확인 완료${NC}"
echo ""

# 3. 프로젝트 삭제 완료 대기 (선택적)
echo -e "${YELLOW}[4/5] 프로젝트 삭제 완료 대기 중...${NC}"

echo "  - 프로젝트 삭제 상태 확인 중..."
sleep 5

REMAINING_PROJECTS=()
for project in "${TARGET_PROJECTS[@]}"; do
    if oc get project "$project" &>/dev/null; then
        REMAINING_PROJECTS+=("$project")
    fi
done

if [ ${#REMAINING_PROJECTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}  ⚠ 다음 프로젝트들이 아직 삭제 중입니다: ${REMAINING_PROJECTS[*]}${NC}"
    echo "  - 삭제는 백그라운드에서 계속 진행됩니다."
else
    echo -e "${GREEN}  ✓ 모든 프로젝트가 삭제되었습니다.${NC}"
fi

echo -e "${GREEN}✓ 프로젝트 삭제 확인 완료${NC}"
echo ""

# 4. 백업 파일 정리
echo -e "${YELLOW}[5/5] 백업 파일 정리 중...${NC}"

cd "$LAB_DIR"

# 백업 파일들 삭제
BACKUP_FILES=(
    "projects-backup.yaml"
    "rolebindings-team-alpha-backup.yaml"
    "rolebindings-team-beta-backup.yaml"
    "rolebindings-finance-apps-backup.yaml"
    "rolebindings-it-automation-backup.yaml"
)

for file in "${BACKUP_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "  ✓ $file 삭제됨"
    fi
done

echo -e "${GREEN}✓ 백업 파일 정리 완료${NC}"
echo ""

# 정리 완료 메시지
echo -e "${BLUE}=========================================="
echo "실습 환경 정리 완료!"
echo "=========================================="
echo ""
echo "다음 항목들이 정리되었습니다:"
echo "✓ 실습용 프로젝트 삭제 (team-alpha, team-beta, finance-apps, it-automation)"
echo "✓ 프로젝트별 사용자 권한 자동 정리"
echo "✓ 백업 파일 정리"
echo ""
echo "참고사항:"
echo "- 사용자 계정은 유지됩니다 (3-1 실습 결과)"
echo "- 클러스터 레벨 권한은 유지됩니다 (3-3 실습 결과)"
echo "- 프로젝트별 권한만 정리되었습니다"
echo ""
echo "현재 프로젝트 상태 확인:"
echo "oc get projects | grep -E 'team-alpha|team-beta|finance-apps|it-automation'"
echo ""
echo "전체 실습 시리즈 정리를 원하는 경우:"
echo "1. Lab 3-3.2 정리 (현재 완료)"
echo "2. Lab 3-3.1 정리: cd ../3-3.1 && ./settings/cleanup-lab.sh"
echo "3. Lab 3-1 정리: cd ../3-1 && ./settings/cleanup-lab.sh"
echo -e "${NC}"

echo -e "${GREEN}✓ 전체 정리 작업 완료${NC}"