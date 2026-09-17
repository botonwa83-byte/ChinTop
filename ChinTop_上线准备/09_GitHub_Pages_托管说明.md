# GitHub Pages 托管说明（隐私政策 / 用户协议 / 技术支持）

> 静态页面已放在本仓库根目录 `docs/`，推送并启用 Pages 即可。

## 仓库与文件

- 仓库：`botonwa83-byte/ChinTop`（本地目录 `ChinTopNative`）

```text
docs/
├── index.html      首页（汇总三个链接）
├── privacy.html    隐私政策（ASC 必填 URL）
├── terms.html      用户协议（EULA）
└── support.html    技术支持（ASC 支持网址）
```

## 启用步骤

1. 提交并推送：

```sh
cd /Users/fengwang/Documents/trae_projects/ChinTopNative
git add docs
git commit -m "docs: add ChinTop launch policy pages"
git push
```

2. 打开 GitHub 仓库 → Settings → Pages：

- Source 选 `Deploy from a branch`
- Branch 选 `main`
- 目录选 `/docs`
- 保存后等待 1–2 分钟

3. 预期链接：

| 用途 | 链接 |
|------|------|
| 隐私政策（ASC 必填） | `https://botonwa83-byte.github.io/ChinTop/privacy.html` |
| 用户协议 | `https://botonwa83-byte.github.io/ChinTop/terms.html` |
| 技术支持（ASC 支持网址） | `https://botonwa83-byte.github.io/ChinTop/support.html` |
| 首页 | `https://botonwa83-byte.github.io/ChinTop/` |

## App 内对应位置

- `ChinTopApp/ChinLegal.swift` → `ChinLegal.termsURL / privacyURL / supportURL`
- 付费墙底部（`ChinPaywallView`）与「功能」页「关于与协议」（`ChinAppearance.swift`）共用 `ChinLegalLinksView`

> 改仓库名或账号后，必须同步改 `ChinLegal.swift` 里的三个 URL，否则 ASC 审核会打不开链接。

## 备注

- GitHub 免费账户通常要求仓库 Public 才能使用 Pages。
- 也可改用 Cloudflare Pages / Vercel 等任意静态托管，只需同步替换 App 内 URL。
- 页面为纯静态、自适应，无需构建。
