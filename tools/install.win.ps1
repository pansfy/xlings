# 设置变量
$xmakeBinDir = "$env:USERPROFILE\xmake"
$xlingsBinDir = "C:\Users\Public\xlings\.xlings_data\bin"

Write-Output "[xlings]: start detect environment and try to auto config..."

# 检查是否已安装 xmake
if (Get-Command xmake -ErrorAction SilentlyContinue) {
    Write-Output "[xlings]: xmake installed"
}
else {
    Write-Output "[xlings]: start install xmake..."
    $resp = Invoke-WebRequest -Uri https://xmake.io/psget.text -UseBasicParsing
    if ($resp.Content -is [byte[]]) {
        $text = [System.Text.Encoding]::UTF8.GetString($resp.Content) 
    }
    else {
        $text = $resp.Content
    }
    Invoke-Expression $text
}

# 检查是否已安装 Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Output "[xlings]: git installed"
}
else {
    Write-Output "[xlings]: start install git..."
    winget install git.git --accept-source-agreements
}

# 添加 xlings 到 PATH
$regPathKey = "Registry::HKEY_CURRENT_USER\Environment"
$regPath = (Get-ItemProperty -Path $regPathKey -Name PATH).PATH

if ($regPath -notmatch "xlings_data") {
    Write-Output "[xlings]: set xlings to PATH"
    $newPath = "$regPath;$xlingsBinDir"
    Setx PATH "$newPath"
}
else {
    Write-Output "[xlings]: xlings is already in PATH."
}

# 替换原有目录切换逻辑
$xlingsRoot = $PSScriptRoot | Split-Path -Parent

# 严格验证核心目录存在
if (-not (Test-Path "$xlingsRoot\core")) {
    Write-Error "[xlings] FATAL: Core directory missing at: $xlingsRoot\core"
    Read-Host "Press Enter to exit"
    exit 1
}

# 保留路径更新
$env:PATH = "$xlingsBinDir;$xmakeBinDir;$env:PATH"

# 进入核心目录（增加错误处理）
Set-Location "$xlingsRoot\core" -ErrorAction Stop
try {
    xmake xlings unused self enforce-install
    xlings self init
}
finally {
    # 确保返回用户家目录
    Write-Output "[xlings]: Returning to user root directory..."
    Set-Location $env:USERPROFILE -ErrorAction Stop
}

# 安装完 xlings 后的提示
Write-Output "[xlings]: xlings installed"
Write-Output ""
Write-Output "    run xlings help get more information"
Write-Output ""