# GitHub Actions 自动部署配置指南

## 已创建的工作流

文件：`.github/workflows/pages.yml`

### 触发条件
- ✅ 推送到 `main` 分支时
- ✅ `docs/` 目录有变更时
- ✅ 手动触发（workflow_dispatch）

### 部署流程
1. 检出代码
2. 配置 GitHub Pages
3. 上传 `docs/` 目录作为 artifact
4. 自动部署到 GitHub Pages

---

## 需要手动配置的步骤

### 1. 更改 Pages 部署源

访问：https://github.com/theneoai/skill-writer/settings/pages

**更改前：**
- Source: Deploy from a branch
- Branch: main /docs

**更改后：**
- Source: **GitHub Actions**

### 2. 保存设置

点击 "Save" 按钮

### 3. 触发首次部署

**方法A：推送任意更改到 docs/**
```bash
# 本地执行
touch docs/trigger.txt
git add docs/trigger.txt
git commit -m "trigger: deploy pages"
git push origin main
```

**方法B：手动触发**
1. 访问：https://github.com/theneoai/skill-writer/actions
2. 点击 "Deploy GitHub Pages"
3. 点击 "Run workflow"
4. 选择分支：main
5. 点击 "Run workflow"

---

## 验证部署

### 查看部署状态
1. 访问：https://github.com/theneoai/skill-writer/actions
2. 查看 "Deploy GitHub Pages" 工作流运行状态

### 访问站点
部署成功后访问：https://theneoai.github.io/skill-writer

---

## 自动部署行为

配置完成后，以下操作会自动触发部署：

| 操作 | 是否触发 | 说明 |
|------|---------|------|
| 修改 `docs/index.html` | ✅ | 立即部署 |
| 修改 `docs/assets/**` | ✅ | 立即部署 |
| 修改 `README.md` | ❌ | 不触发（不在docs目录） |
| 修改 `.github/workflows/**` | ✅ | 立即部署 |
| 推送 tag | ❌ | 不触发 |

---

## 故障排除

### 问题：Actions 显示 "This workflow has no runs yet"
**解决**：
1. 确保已经在 Settings > Pages 中选择了 "GitHub Actions"
2. 推送任意更改到 docs/ 目录触发首次运行

### 问题：部署成功但页面未更新
**解决**：
1. 清除浏览器缓存（Ctrl+Shift+R 或 Cmd+Shift+R）
2. 检查 Actions 日志中的部署 URL
3. 等待 1-2 分钟（CDN 缓存）

### 问题：Actions 运行失败
**解决**：
1. 检查仓库权限：Settings > Actions > General > Workflow permissions
2. 确保选择了 "Read and write permissions"
3. 勾选 "Allow GitHub Actions to create and approve pull requests"

---

## 配置状态

- ✅ 工作流文件已创建
- ✅ 已推送到 main 分支
- ⏳ 等待手动切换到 GitHub Actions 部署源
- ⏳ 等待首次触发

---

## 下一步

1. 访问 https://github.com/theneoai/skill-writer/settings/pages
2. 将 Source 改为 "GitHub Actions"
3. 点击 Save
4. 推送测试更改或手动触发工作流
