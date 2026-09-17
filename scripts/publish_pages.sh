#!/usr/bin/env bash
# 一键发布法律文档到 GitHub Pages（botonwa83-byte/ChinTop）
# 用法：./scripts/publish_pages.sh
set -euo pipefail

OWNER=botonwa83-byte
REPO=ChinTop
BRANCH=main
DOCS=docs
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "== 发布 $DOCS 到 $OWNER/$REPO"

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  cd "$ROOT"
  git add "$DOCS"
  if git diff --cached --quiet; then
    echo "docs 无变化，跳过提交"
  else
    git commit -m "docs: publish ChinTop legal pages"
  fi
  git push origin HEAD
else
  # 本工程尚未初始化 git：用临时克隆把 docs 推到远端仓库
  TMP="$(mktemp -d)"
  git clone --depth 1 -b "$BRANCH" "https://github.com/$OWNER/$REPO.git" "$TMP/repo"
  rm -rf "$TMP/repo/$DOCS"
  cp -R "$ROOT/$DOCS" "$TMP/repo/$DOCS"
  cd "$TMP/repo"
  git add "$DOCS"
  if git diff --cached --quiet; then
    echo "docs 无变化，跳过提交"
  else
    git -c user.name="ChinTop Bot" -c user.email="botonwa83@gmail.com" \
      commit -m "docs: publish ChinTop legal pages"
    git push origin "$BRANCH"
  fi
  cd "$ROOT"
  rm -rf "$TMP"
fi

echo "== 启用 Pages（$BRANCH /docs）"
if gh api -X POST "repos/$OWNER/$REPO/pages" \
     -f "source[branch]=$BRANCH" -f "source[path]=/docs" >/dev/null 2>&1; then
  echo "Pages 已启用"
else
  echo "Pages 可能已启用或需手动开启：https://github.com/$OWNER/$REPO/settings/pages"
fi

echo "== 校验（等待 60s 让 Pages 首次构建完成后再跑一次）"
for f in index privacy terms support; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://$OWNER.github.io/$REPO/$f.html")
  echo "  $f.html -> $code"
done
