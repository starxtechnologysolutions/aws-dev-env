# Umi Go 汽车租赁运营管理后台

<div align="center">

![Vue](https://img.shields.io/badge/Vue-3.5.22-4FC08D?style=flat-square&logo=vue.js)
![TypeScript](https://img.shields.io/badge/TypeScript-5.9.3-3178C6?style=flat-square&logo=typescript)
![Vite](https://img.shields.io/badge/Vite-7.1.12-646CFF?style=flat-square&logo=vite)
![NaiveUI](https://img.shields.io/badge/Naive%20UI-2.43.1-18A058?style=flat-square)
![UnoCSS](https://img.shields.io/badge/UnoCSS-0.66.5-333333?style=flat-square&logo=unocss)

基于 Vue3 + Vite + TypeScript + NaiveUI 开发的现代化企业级后台管理系统

</div>

## 项目介绍

Umi Go 是一个基于现代技术栈构建的汽车租赁运营管理后台系统，提供了完整的后台管理解决方案。系统采用企业级架构设计，支持多语言、暗黑模式、动态路由、权限管理等核心功能。

## 技术特性

### 核心框架
- ✅ **Vue 3.5** - 渐进式 JavaScript 框架
- ✅ **Vite 7** - 下一代前端构建工具
- ✅ **TypeScript** - JavaScript 的超集，提供类型支持
- ✅ **Vue Router 4** - 官方路由管理器

### UI 框架
- ✅ **Naive UI 2.4** - 高质量 Vue 3 组件库
- ✅ **Pro Naive UI 3.1** - Naive UI 增强组件库
- ✅ **UnoCSS** - 即时原子化 CSS 引擎

### 功能特性
- ✅ 国际化 (Vue I18n) - 支持中英文切换
- ✅ 暗黑模式 - 支持明暗主题切换
- ✅ 动态路由 - 基于 elegant-router 自动生成路由
- ✅ 权限管理 - 完整的 RBAC 权限控制系统
- ✅ 状态管理 - 基于 Pinia 的状态管理
- ✅ HTTP 请求 - 集成 Alova 和 Axios
- ✅ 图表可视化 - 集成 ECharts、AntV、VChart
- ✅ 富文本编辑器 - WangEditor 和 Vditor 支持
- ✅ Excel 导入导出 - XLSX 集成
- ✅ 打印功能 - Print.js 集成
- ✅ 地图集成 - 高德地图、百度地图、腾讯地图
- ✅ PDF 预览 - Vue PDF Embed 支持
- ✅ 甘特图 - DHTMLX Gantt 和 VTable Gantt
- ✅ 视频播放器 - XG Player 集成

## 快速开始

### 环境要求

- Node.js >= 20.19.0
- pnpm >= 10.5.0

### 安装依赖

```bash
# 安装 pnpm（如果还未安装）
npm install -g pnpm

# 安装依赖
pnpm install
```

### 开发运行

```bash
# 启动开发服务器（测试环境）
pnpm dev

# 启动开发服务器（生产环境）
pnpm dev:prod
```

访问 http://localhost:9527 查看应用

### 构建部署

```bash
# 构建测试环境
pnpm build:test

# 构建生产环境
pnpm build
```

构建产物位于 `dist` 目录

### 其他命令

```bash
# 类型检查
pnpm typecheck

# 代码规范检查
pnpm lint

# 清理构建缓存
pnpm cleanup

# 预览构建产物
pnpm preview
```

## 项目结构

```
uni-go-admin/
├── build/              # 构建配置
│   ├── config/         # 配置文件
│   └── plugins/        # Vite 插件
├── packages/           # 内部包
│   ├── alova/          # Alova 请求封装
│   ├── axios/          # Axios 请求封装
│   ├── hooks/          # 通用 Hooks
│   ├── materials/      # 物料库
│   ├── scripts/        # 构建脚本
│   ├── utils/          # 工具函数
│   └── uno-preset/     # UnoCSS 预设
├── public/             # 静态资源
├── src/                # 源代码
│   ├── assets/         # 资源文件
│   ├── components/     # 公共组件
│   ├── constants/      # 常量定义
│   ├── enum/           # 枚举定义
│   ├── hooks/          # 业务 Hooks
│   ├── layouts/        # 布局组件
│   ├── locales/        # 国际化
│   ├── plugins/        # 插件配置
│   ├── router/         # 路由配置
│   ├── service/        # API 服务
│   ├── store/          # 状态管理
│   ├── styles/         # 样式文件
│   ├── theme/          # 主题配置
│   ├── typings/        # 类型定义
│   ├── utils/          # 工具函数
│   └── views/          # 页面组件
├── index.html          # HTML 入口
├── package.json        # 项目配置
├── tsconfig.json       # TypeScript 配置
├── uno.config.ts       # UnoCSS 配置
└── vite.config.ts      # Vite 配置
```

## 核心功能模块

### 1. 权限管理
- 用户管理 - 用户信息管理
- 角色管理 - 角色权限配置
- 菜单管理 - 菜单权限设置
- 按钮权限 - 细粒度权限控制

### 2. 数据展示
- 数据表格 - 支持分页、排序、搜索
- 图表可视化 - ECharts、AntV、VChart
- 数据导出 - Excel 导出功能

### 3. 富文本编辑
- Markdown 编辑器
- 富文本编辑器
- 代码高亮


## 技术选型

| 分类 | 技术 | 版本 |
|------|------|------|
| 框架 | Vue | 3.5.22 |
| 构建工具 | Vite | 7.1.12 |
| 语言 | TypeScript | 5.9.3 |
| UI 框架 | Naive UI | 2.43.1 |
| CSS 框架 | UnoCSS | 0.66.5 |
| 状态管理 | Pinia | 3.0.3 |
| 路由 | Vue Router | 4.6.3 |
| 国际化 | Vue I18n | 11.1.12 |
| HTTP 请求 | Alova | - |
| HTTP 请求 | Axios | - |
| 图表 | ECharts | 6.0.0 |
| 日期处理 | Day.js | 1.11.18 |
| 图标 | Iconify | - |

## 浏览器支持

现代浏览器（除 IE 外）

| [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/edge/edge_48x48.png" alt="IE / Edge" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)</br>Edge | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/firefox/firefox_48x48.png" alt="Firefox" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)</br>Firefox | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/chrome/chrome_48x48.png" alt="Chrome" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)</br>Chrome | [<img src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/safari/safari_48x48.png" alt="Safari" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)</br>Safari |
| --------- | --------- | --------- | --------- |
| Latest ✔ | Latest ✔ | Latest ✔ | Latest ✔ |

## 开发指南

### 代码规范
项目使用 ESLint + Prettier 进行代码规范检查：

```bash
# 修复代码规范问题
pnpm lint
```

### Git 提交规范
项目使用 [conventional commits](https://www.conventionalcommits.org/) 规范：

```bash
# 交互式提交（中文）
pnpm commit:zh

# 交互式提交（英文）
pnpm commit
```

### 路由生成
项目使用 elegant-router 自动生成路由：

```bash
# 生成路由
pnpm gen-route
```

## 作者

**Andy Kong**


