[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$TestRoot)

$ErrorActionPreference='Stop'
$TestRoot=[IO.Path]::GetFullPath($TestRoot)
$allowed=[IO.Path]::GetFullPath('D:\环境工具总结\test')
if(-not $TestRoot.StartsWith($allowed.TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw '测试路径越界'}
if(Test-Path -LiteralPath $TestRoot){Remove-Item -LiteralPath $TestRoot -Recurse -Force}
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
$sentinel=Join-Path $TestRoot '用户素材-绝对不能修改.txt'
[IO.File]::WriteAllText($sentinel,'KEEP',[Text.UTF8Encoding]::new($false))
$before=(Get-FileHash -Algorithm SHA256 -LiteralPath $sentinel).Hash
& (Join-Path $PSScriptRoot '..\install.ps1') -InstallRoot (Join-Path $TestRoot 'env') -CcSwitchRoot (Join-Path $TestRoot 'cc-switch') -ShortcutRoot (Join-Path $TestRoot 'shortcuts')
$after=(Get-FileHash -Algorithm SHA256 -LiteralPath $sentinel).Hash
if($before -ne $after){throw '素材保护测试失败'}
$state=Get-Content -LiteralPath (Join-Path $TestRoot 'env\install-state.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if(@($state.material_directories_touched).Count -ne 0){throw '安装状态报告触碰了素材目录'}
Write-Output 'TEST PASSED'
