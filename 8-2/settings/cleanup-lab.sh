#!/bin/bash

echo "=============================================="
echo "DO280 Lab 8-1 & 8-2: 실습 환경 정리"
echo "=============================================="
echo ""

read -p "정말 실습 환경을 정리하시겠습니까? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "취소되었습니다."
    exit 0
fi

echo ""
echo "🧹 리소스 정리 중..."
echo ""

echo "--- 8-2 리소스 정리 ---"
# team 애플리케이션 리소스 삭제 (8-2)
oc delete deployment team -n production 2>/dev/null && echo "✓ team Deployment 삭제 완료" || echo "ℹ team Deployment 없음"
oc delete service team -n production 2>/dev/null && echo "✓ team Service 삭제 완료" || echo "ℹ team Service 없음"
oc delete route team -n production 2>/dev/null && echo "✓ team Route 삭제 완료" || echo "ℹ team Route 없음"
oc delete configmap team-config -n production 2>/dev/null && echo "✓ team ConfigMap 삭제 완료" || echo "ℹ team ConfigMap 없음"

echo ""
echo "--- 8-1 리소스 정리 ---"
# root-app 리소스 삭제 (8-1)
oc delete deployment root-app -n production 2>/dev/null && echo "✓ root-app Deployment 삭제 완료" || echo "ℹ root-app Deployment 없음"

# anyuid SCC에서 redhat-sa 제거
oc adm policy remove-scc-from-user anyuid -z redhat-sa -n production 2>/dev/null && echo "✓ anyuid SCC 제거 완료" || echo "ℹ anyuid SCC 바인딩 없음"

# redhat-sa ServiceAccount 삭제
oc delete serviceaccount redhat-sa -n production 2>/dev/null && echo "✓ redhat-sa ServiceAccount 삭제 완료" || echo "ℹ redhat-sa ServiceAccount 없음"

echo ""
echo "--- production 프로젝트 삭제 ---"
# production 프로젝트 전체 삭제
oc delete project production 2>/dev/null && echo "✓ production 프로젝트 삭제 완료" || echo "ℹ production 프로젝트 없음"

echo ""
echo "=============================================="
echo "✅ 정리 완료!"
echo "=============================================="
echo ""
echo "삭제된 리소스:"
echo "  - production 프로젝트 (모든 리소스 포함)"
echo "  - redhat-sa ServiceAccount"
echo "  - anyuid SCC 바인딩"
echo "  - root-app Deployment (8-1)"
echo "  - team Deployment, Service, Route, ConfigMap (8-2)"
echo ""
