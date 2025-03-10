# Candystick

Candystick 是一个基于 Shiny 开发的股票交易训练系统，旨在帮助用户通过模拟交易来提升交易技能。系统提供了训练模式和对战模式两种学习方式，让用户在零风险的环境中积累交易经验。

## 功能特点

- **训练模式**：提供个性化的交易训练环境
  - 随机选择股票进行训练
  - 实时K线图显示
  - 技术指标支持（MA、BOLL等）
  - 模拟交易功能（条件单、市价单）
  - 账户资金跟踪
  - 收益率统计

- **对战模式**：支持多用户同时交易对战（开发中）

## 系统要求

- R >= 4.0.0
- RStudio（推荐）

## 依赖包

```R
library(shiny)
library(shinythemes)
library(shinyWidgets)
library(shinyjs)
library(tidyverse)
library(config)
library(RSQLite)
```

## 安装指南

1. 克隆项目到本地
```bash
git clone git@github.com:guowei-xie/Candystick.git
cd Candystick
```

2. 安装依赖包
```R
install.packages(c("shiny", "shinythemes", "shinyWidgets", "shinyjs", "tidyverse", "config", "RSQLite"))
```

3. 初始化数据库
```R
source("init.R")
```

4. 添加环境变量

首先需要在 [Tushare Pro](https://tushare.pro/) 平台注册账号并获取 token。

对于 bash 用户，编辑 `~/.bashrc`：
```bash
echo 'export tushare_token="你的token"' >> ~/.bashrc
source ~/.bashrc
```

对于 zsh 用户，编辑 `~/.zshrc`：
```bash
echo 'export tushare_token="你的token"' >> ~/.zshrc
source ~/.zshrc
```

验证环境变量是否设置成功：
```bash
echo $tushare_token
```


## 配置说明

系统配置文件为 `config.yml`，主要配置项包括：

```yaml
default:
  dev: TRUE
  title: Candystick
  theme: yeti

database:
  path: db/
  name: candy.db
  
train:  
  initial: 100000 # 初始资金
  market: ["主板", "创业板", "北交所", "科创板"] # 股票池范围
  recent_years: 3 # 历史数据年限
  recent_days: 120 # 显示K线数量
  train_days: 6 # 训练天数
```

## 使用指南

1. 启动应用
```R
shiny::runApp()
```

2. 训练模式
   - 系统随机选择一支股票
   - 显示历史K线图和技术指标
   - 通过"交易"按钮进行买卖操作
   - 通过"观望"按钮切换到下一个交易时间点
   - 完成指定天数的训练后可选择继续训练

3. 对战模式（开发中）
   - 多用户同时交易
   - 实时排名
   - 收益率对比

## 项目结构

```
├── app.R           # 应用入口
├── config.yml      # 配置文件
├── init.R          # 初始化脚本
├── module/         # 模块服务器
├── src/           # 核心功能
├── ui/            # 界面组件
└── www/           # 静态资源
```

## 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交改动 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request


## 联系方式

如有问题或建议，欢迎提交 Issue 或 Pull Request。