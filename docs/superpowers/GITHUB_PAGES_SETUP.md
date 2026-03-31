# GitHub Pages 设置指南

## 问题诊断

GitHub Pages 需要在仓库设置中手动启用。即使文件已经推送到 `docs/` 目录，也需要在 GitHub 后台进行配置。

## 解决步骤

### 1. 访问仓库设置
打开 https://github.com/theneoai/skill-writer/settings/pages

### 2. 配置 Source
在 "Source" 部分：
- 选择 **"Deploy from a branch"**
- Branch: 选择 **"main"**
- Folder: 选择 **"/docs"**
- 点击 **"Save"**

### 3. 等待部署
保存后，GitHub 会自动部署 Pages。通常需要 1-5 分钟。

### 4. 访问地址
部署完成后，站点将可以通过以下地址访问：
```
https://theneoai.github.io/skill-writer
```

## 验证部署状态

### 方法1：查看 GitHub 后台
1. 访问 https://github.com/theneoai/skill-writer/settings/pages
2. 查看顶部的部署状态（绿色勾表示成功）

### 方法2：查看 Actions
1. 访问 https://github.com/theneoai/skill-writer/actions
2. 查看是否有 "pages-build-deployment" 工作流运行

## 常见问题

### Q: 保存后显示 404
**A**: 等待 1-5 分钟，GitHub Pages 需要时间部署。如果超过10分钟仍404，检查：
- 文件是否确实在 `docs/` 目录
- index.html 是否在 `docs/` 根目录

### Q: 样式没有加载
**A**: 检查浏览器控制台是否有 CORS 错误。确保 CSS 文件路径正确：
- 应该是相对路径：`assets/css/style.css`
- 不是绝对路径：`/assets/css/style.css`

### Q: 如何自定义域名
**A**: 在 Pages 设置页面的 "Custom domain" 部分添加你的域名，然后创建 CNAME 文件。

## 当前状态

- ✅ 文件已推送到 `docs/` 目录
- ✅ index.html 存在
- ✅ CSS 和 JS 文件存在
- ⏳ 等待 GitHub 后台启用 Pages

## 下一步

请访问 https://github.com/theneoai/skill-writer/settings/pages 启用 GitHub Pages。

启用后，站点将在几分钟内上线。
