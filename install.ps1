[CmdletBinding()]
param(
  [string]$InstallRoot = '',
  [string]$CcSwitchRoot = '',
  [string]$ShortcutRoot = '',
  [switch]$ReplaceExisting
)

$ErrorActionPreference = 'Stop'
$packageRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
  $InstallRoot = Join-Path $env:LOCALAPPDATA 'env4BC'
}
$InstallRoot = [IO.Path]::GetFullPath($InstallRoot)
$stateRoot = $InstallRoot
$toolRoot = Join-Path $InstallRoot 'tools'
if ([string]::IsNullOrWhiteSpace($CcSwitchRoot)) {
  $ccTargetRoot = Join-Path $env:LOCALAPPDATA 'Programs\CC Switch'
} else {
  $ccTargetRoot = [IO.Path]::GetFullPath($CcSwitchRoot)
}
$ccSource = Join-Path $packageRoot 'program\cc-switch\cc-switch.exe'
$ccTarget = Join-Path $ccTargetRoot 'cc-switch.exe'
$apiSource = Join-Path $packageRoot 'program\Seedance API配置工具.exe'
$apiTarget = Join-Path $toolRoot 'Seedance API配置工具.exe'

New-Item -ItemType Directory -Force -Path $toolRoot,$ccTargetRoot | Out-Null

function Install-WingetComponentIfMissing {
  param([string]$Command,[string]$PackageId,[string]$Name)
  if (Get-Command $Command -ErrorAction SilentlyContinue) {
    Write-Output "$Name：已存在，跳过。"
    return 'skipped-existing'
  }
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "$Name 缺失，且本机没有可信的 winget 安装源。已停止，请联系维护人员处理。"
  }
  & winget install --id $PackageId --exact --accept-package-agreements --accept-source-agreements --silent
  if ($LASTEXITCODE -ne 0) { throw "$Name 安装失败。已停止，请联系维护人员处理。" }
  $env:PATH = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
  if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
    throw "$Name 已安装但当前进程仍无法使用。已停止，请联系维护人员处理或重启 Codex 后重试。"
  }
  Write-Output "$Name：已通过 winget 安装。"
  return 'installed-winget'
}

$pythonResult = Install-WingetComponentIfMissing -Command 'py' -PackageId 'Python.Python.3.12' -Name 'Python'
$ffmpegResult = Install-WingetComponentIfMissing -Command 'ffmpeg' -PackageId 'Gyan.FFmpeg.Shared' -Name 'ffmpeg'

function Install-ProgramIfNeeded {
  param([string]$Source,[string]$Target,[string]$Name)
  if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "安装包缺少：$Source" }
  $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Source).Hash
  if (Test-Path -LiteralPath $Target -PathType Leaf) {
    $targetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Target).Hash
    if ($sourceHash -eq $targetHash) {
      Write-Output "$Name：已存在且一致，跳过。"
      return 'skipped-identical'
    }
    if (-not $ReplaceExisting) {
      Write-Output "$Name：检测到已有不同版本，默认保留；未修改。"
      return 'preserved-different'
    }
    $backup = "$Target.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item -LiteralPath $Target -Destination $backup -Force
    Write-Output "$Name：已备份到 $backup"
  }
  Copy-Item -LiteralPath $Source -Destination $Target -Force
  Write-Output "$Name：已安装 $Target"
  return 'installed'
}

$ccResult = Install-ProgramIfNeeded -Source $ccSource -Target $ccTarget -Name 'CC Switch'
$apiResult = Install-ProgramIfNeeded -Source $apiSource -Target $apiTarget -Name 'Seedance API配置工具'

Copy-Item -LiteralPath (Join-Path $packageRoot 'scripts\configure_ccswitch_model.py') -Destination (Join-Path $toolRoot 'configure_ccswitch_model.py') -Force
Copy-Item -LiteralPath (Join-Path $packageRoot 'scripts\Configure-SeedanceApi-GUI.pyw') -Destination (Join-Path $toolRoot 'Configure-SeedanceApi-GUI.pyw') -Force
Copy-Item -LiteralPath (Join-Path $packageRoot 'docs\API与CCSwitch配置.md') -Destination (Join-Path $toolRoot 'API与CCSwitch配置.md') -Force

$shell = New-Object -ComObject WScript.Shell
$shortcutDirectory = if ([string]::IsNullOrWhiteSpace($ShortcutRoot)) { [Environment]::GetFolderPath('Desktop') } else { [IO.Path]::GetFullPath($ShortcutRoot) }
New-Item -ItemType Directory -Force -Path $shortcutDirectory | Out-Null
foreach ($entry in @(
  @{Name='CC Switch.lnk'; Target=$ccTarget; Work=$ccTargetRoot; Description='env4BC CC Switch'},
  @{Name='Seedance API配置工具.lnk'; Target=$apiTarget; Work=$toolRoot; Description='env4BC API配置工具'}
)) {
  if (-not (Test-Path -LiteralPath $entry.Target -PathType Leaf)) { continue }
  $shortcut = $shell.CreateShortcut((Join-Path $shortcutDirectory $entry.Name))
  $shortcut.TargetPath = $entry.Target
  $shortcut.WorkingDirectory = $entry.Work
  $shortcut.Description = $entry.Description
  $shortcut.Save()
}

$state = [ordered]@{
  schema_version = 1
  version = '1.1.0'
  install_root = $InstallRoot
  cc_switch = @{path=$ccTarget; result=$ccResult}
  seedance_api_tool = @{path=$apiTarget; result=$apiResult}
  python = @{command='py'; result=$pythonResult}
  ffmpeg = @{command='ffmpeg'; result=$ffmpegResult}
  material_directories_touched = @()
  installed_at = (Get-Date).ToString('o')
}
[IO.File]::WriteAllText((Join-Path $stateRoot 'install-state.json'), ($state | ConvertTo-Json -Depth 8) + "`r`n", [Text.UTF8Encoding]::new($false))
Write-Output "env4BC 安装完成。未扫描或修改任何业务素材目录。"
