---
date: 2026-05-01
tags:
  - Github开源项目
---

> [官方文档](https://quartz.jzhao.xyz/)
> [Github网址](https://github.com/jackyzha0/quartz)

Quartz 4 是一个快速、开箱即用的**静态网站生成器**，能将 Markdown 内容转换为功能完整的网站。 它是 Obsidian Publish 的免费替代方案，非常适合搭建个人笔记站、数字花园（Digital Garden）。

# 环境要求

需要**Node.js v22** 和 **npm v10.9.2**

# 使用方法

初始化一个仓库
```
# 1. 克隆仓库
git clone https://github.com/jackyzha0/quartz.git
cd quartz

# 2. 安装依赖
npm i

# 3. 初始化项目（按提示操作）
npx quartz create
```

放入自己的笔记到项目中的`content`目录下
```
quartz/
├── content/          ← 你的 Markdown 笔记放这里
├── quartz/           ← 核心框架代码（不要修改）
├── quartz.config.ts  ← 主配置文件
└── quartz.layout.ts  ← 布局配置文件
```

本地预览
```
npx quartz build --serve
```
默认在 `http://localhost:8080` 预览网站。

部署线上
```
# 同步并推送内容（自动触发部署）
npx quartz sync
```