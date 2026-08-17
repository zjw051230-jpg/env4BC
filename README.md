# 媒体生产环境

`media-production-env` 为配音和视频工具提供共用的 Windows 运行环境，包括 Python、ffmpeg、Codex、CC Switch 检查以及 Seedance API 的本机配置入口。

它只负责环境，不管理项目、素材或生成结果。API Key、provider 配置和 CC Switch 用户数据库始终保留在本机。

## 安装

双击 `Env4BCSetup.pyw`。安装程序会先检查现有组件：

- 版本符合时直接跳过；
- 缺少组件时只安装缺少的部分；
- 已安装其他版本时默认保留，明确选择后才会备份并替换；
- 不复制或覆盖 CC Switch 的用户数据库。

Python 和 ffmpeg 通过 Windows `winget` 获取。正式安装包应来自本仓库的 Release，并校验 SHA-256。

## 管理范围

- Python、ffmpeg、Codex 和 CC Switch 的可用性检查；
- CC Switch 程序文件与指定的本地路由；
- Seedance API 的本机密钥配置；
- 桌面快捷方式与环境状态文件。

项目素材、生成文件、快照、任务日志和业务目录不在本工具的管理范围内。

## 配套仓库

- [video-production-kit](https://github.com/zjw051230-jpg/video-production-kit)
- [voice-production-kit](https://github.com/zjw051230-jpg/voice-production-kit)

首次安装前请阅读 [首次安装说明](docs/首次安装说明.md)；更新和修复规则见 [更新与修复规则](docs/更新与修复规则.md)。
