# 安全规则

不得提交 API Key、Cookie、provider 密钥、CC Switch 用户数据库、业务素材或任务状态。

发布包只能包含 `program/cc-switch/cc-switch.exe` 程序本体及许可、补丁说明。严禁从 `%USERPROFILE%\.cc-switch`、其 `backups` 子目录或任何工作区复制文件；`cc-switch.db`、WAL/SHM、数据库备份、provider 导出、`.env`、API 池和安装状态都不得进入 Git 或 ZIP。构建前必须运行 `scripts/validate_package.py`，校验失败时禁止发布。

模型路由只允许在选定 Codex provider 的 `localProxyRequestOverrides.modelRoutes` 中精确设置 `gpt-5.5 -> deepseek-v4-pro`。不得修改任何其他模型、provider、API Key 或 base URL。
