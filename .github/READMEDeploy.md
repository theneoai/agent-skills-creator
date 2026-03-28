# GitHub Pages 部署说明

本文档说明 Skill Engineering 项目的 GitHub Pages 部署配置。

## 部署配置

部署配置文件位于 `.github/workflows/pages.yml`。

### 工作流程

1. **触发条件**: 当 `main` 分支有 push 时自动触发，也可手动触发
2. **部署环境**: 使用 GitHub Pages 环境 `github-pages`
3. **部署路径**: `docs/` 目录作为网站根目录

### 部署步骤

1. `actions/checkout@v4` - 检出代码
2. `actions/configure-pages@v4` - 配置 GitHub Pages
3. `actions/upload-pages-artifact@v3` - 上传 docs/ 目录作为 artifact
4. `actions/deploy-pages@v4` - 部署到 GitHub Pages

### 访问网站

部署完成后，网站将在以下地址可用：
`https://[username].github.io/[repository]/`

## 本地预览

如需本地预览静态网站，可使用任意静态文件服务器：

```bash
# 使用 Python
cd docs && python -m http.server 8000

# 使用 npx
npx serve docs
```