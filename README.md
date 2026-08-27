<p align="center">
  <img src="./Resources/AppIcon.png" alt="Codex 模型管理器图标" width="128">
</p>

<h1 align="center">Codex 模型管理器</h1>

<p align="center">
  <img src="https://img.shields.io/badge/license-Apache--2.0-32CD32?style=flat-square&logo=apache&logoColor=white" alt="Apache License 2.0">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-6C757D?style=flat-square&logo=apple&logoColor=white" alt="macOS 14 或更高版本">
</p>

Codex 模型管理器是一款原生 macOS 应用，用来查看和维护 Codex 的官方模型与自定义模型目录。它把模型状态、定时同步记录和新增模型入口集中在一个窗口中，同时继续沿用现有的模型来源与同步任务，不另建一套配置。

## 主要功能

- 查看 OpenAI 官方模型、自定义模型及当前合并结果
- 查看定时同步任务的状态、最后执行时间、退出码和执行周期
- 查看每次同步是否产生改动，以及当时的 Codex 版本和模型数量
- 以现有自定义模型为能力模板新增模型
- 写入前自动备份自定义模型来源文件，写入后调用已配置的同步任务

## 工作方式

应用只负责读取状态和发出明确的管理命令，模型数据仍由原有文件与定时任务负责：

```text
自定义模型源 ──> 定时同步任务 ──> 合并模型目录 ──> Codex
     ^                  |
     |                  └── 同步日志与错误日志
     └── 应用新增模型时只写这里
```

新增模型时，应用先备份自定义模型来源文件，再以原子写入方式更新该文件，最后通过 `launchctl kickstart` 运行既有任务。应用不会直接修改合并模型目录，也不会改写 Codex 自带的官方模型。

## 环境要求

- macOS 14 或更高版本
- Xcode 命令行工具
- Swift 5.10 或兼容版本
- 已安装并加载的模型目录同步任务

## 本机配置

仓库只提供不含个人路径的配置样例。首次运行前，先建立本机配置：

```bash
cp Config/config.example.json Config/local.json
```

然后根据本机实际情况修改 `Config/local.json`。该文件已加入 `.gitignore`，不会进入 Git。构建脚本会以 `0600` 权限把它安装到：

```text
~/Library/Application Support/CodexModelManager/config.json
```

配置字段说明：

| 字段 | 用途 |
| --- | --- |
| `customSourcePath` | 自定义模型的唯一来源文件 |
| `mergedCatalogPath` | 同步后供 Codex 读取的合并目录 |
| `syncLogPath` | 每次同步产生的结构化日志 |
| `errorLogPath` | 同步任务的错误日志 |
| `launchAgentPlistPath` | macOS 定时任务的配置文件 |
| `launchAgentLabel` | `launchctl` 使用的任务标识 |
| `backupDirectoryPath` | 新增模型前保存备份的目录 |

路径必须是绝对路径或以 `~/` 开头的路径。配置中不要放令牌、密钥或其他凭据。若未安装配置，应用仍能构建和启动，但会明确提示缺少配置，涉及模型目录的操作将保持禁用。

## 构建与运行

在项目根目录执行：

```bash
./script/build_and_run.sh
```

构建、签名并检查应用是否成功启动：

```bash
./script/build_and_run.sh --verify
```

应用会安装到：

```text
~/Applications/CodexModelManager.app
```

构建脚本会停止旧进程、编译 Swift 包、生成应用包、安装本机配置、完成临时签名并启动最新版本。

## 日常使用

概览页用于确认同步任务是否健康，以及最近一次执行是否更新了模型目录。模型页用于查看官方与自定义模型的能力、上下文窗口和来源。新增模型时需要选择一个现有自定义模型作为模板；上下文窗口和图像输入能力会先从模板复制，再由用户确认。

上下文窗口不是从模型供应商接口自动推断的。应用读取的是当前模型目录中已经记录的值；普通模型列表接口通常不提供这一字段，因此新增模型时必须由本地模板或用户输入确定。

## 项目结构

```text
Config/       可公开的配置样例；本机配置不会进入 Git
Resources/    应用图标等资源
Sources/      SwiftUI 界面、状态管理和模型目录服务
Tests/        配置解析与模型目录写入测试
script/       构建、安装和运行入口
```

## 测试

```bash
swift test
```

提交改动前还应执行：

```bash
./script/build_and_run.sh --verify
```

前者验证配置解析和模型目录处理，后者验证真实的 macOS 应用构建、签名、安装与启动路径。

## 公开发布边界

应用代码不包含个人用户目录、模型文件名或定时任务标识；这些内容只存在于被忽略的本机配置中。公开仓库前仍应检查待提交文件中是否含有凭据、个人路径或运行日志，并根据发布方式补充签名、归档和公证流程。当前构建脚本使用临时签名，适合本机运行，不代表可分发版本已经通过 Apple 公证。

## 许可证

本项目采用 [Apache License 2.0](./LICENSE) 授权。
