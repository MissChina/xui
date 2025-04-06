# PowerShell build script for xui
# 此脚本用于在 Windows 环境下构建 xui 的 Linux 发布版本

# 设置颜色
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Yellow"
$DefaultColor = "White"

# 版本设置
$Version = "1.0.0"
Write-Host "Building xui v$Version" -ForegroundColor $InfoColor

# 创建发布目录
$ReleaseDir = "release"
if (-not (Test-Path $ReleaseDir)) {
    New-Item -ItemType Directory -Path $ReleaseDir | Out-Null
}
Write-Host "Creating release directory: $ReleaseDir" -ForegroundColor $SuccessColor

# 支持的架构
$Architectures = @("amd64", "arm64")

# 构建函数
function Build-Xui {
    param (
        [string]$Arch
    )
    
    Write-Host "Building $Arch version..." -ForegroundColor $InfoColor
    
    # 创建临时构建目录
    $TempDir = "temp-$Arch"
    if (Test-Path $TempDir) {
        Remove-Item -Recurse -Force $TempDir
    }
    New-Item -ItemType Directory -Path "$TempDir/bin" -Force | Out-Null
    
    # 设置 Go 环境变量
    $env:GOOS = "linux"
    $env:GOARCH = $Arch
    
    # 编译主程序
    Write-Host "Compiling main program..." -ForegroundColor $InfoColor
    go build -o "$TempDir/xui" main.go
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed!" -ForegroundColor $ErrorColor
        exit 1
    }
    
    # 复制文件 - 使用前斜杠作为路径分隔符
    Write-Host "Copying files..." -ForegroundColor $InfoColor
    
    # 复制 Xray 二进制文件
    $XrayBinary = "bin/xray-linux-$Arch"
    if (Test-Path $XrayBinary) {
        Copy-Item $XrayBinary -Destination "$TempDir/bin/"
    } else {
        Write-Host "Warning: $XrayBinary not found" -ForegroundColor $ErrorColor
    }
    
    # 复制 GeoIP 数据
    try {
        Copy-Item "bin/geoip.dat" -Destination "$TempDir/bin/" -ErrorAction Stop
    } catch {
        Write-Host "Warning: bin/geoip.dat not found" -ForegroundColor $ErrorColor
    }
    
    try {
        Copy-Item "bin/geosite.dat" -Destination "$TempDir/bin/" -ErrorAction Stop
    } catch {
        Write-Host "Warning: bin/geosite.dat not found" -ForegroundColor $ErrorColor
    }
    
    # 复制脚本和配置文件
    try {
        Copy-Item "install.sh" -Destination "$TempDir/" -ErrorAction Stop
    } catch {
        Write-Host "Warning: install.sh not found" -ForegroundColor $ErrorColor
    }
    
    try {
        Copy-Item "xui.service" -Destination "$TempDir/" -ErrorAction Stop
    } catch {
        Write-Host "Warning: xui.service not found" -ForegroundColor $ErrorColor
    }
    
    try {
        Copy-Item "xui.sh" -Destination "$TempDir/" -ErrorAction Stop
    } catch {
        Write-Host "Warning: xui.sh not found" -ForegroundColor $ErrorColor
    }
    
    # 确保所有文本文件使用 Unix 风格的行结束符
    Get-ChildItem -Path $TempDir -Recurse -Include "*.sh", "*.service" | ForEach-Object {
        $content = Get-Content -Path $_.FullName -Raw
        $unixContent = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($_.FullName, $unixContent)
        Write-Host "  Converted $($_.Name) to Unix format" -ForegroundColor $InfoColor
    }
    
    # 创建压缩包
    Write-Host "Creating packages..." -ForegroundColor $InfoColor
    
    # 创建 tar.gz 包
    try {
        # 检查是否安装了 tar
        if (Get-Command tar -ErrorAction SilentlyContinue) {
            # 创建 tar.gz 文件 (简化方法)
            Write-Host "  Creating tar.gz package..." -ForegroundColor $InfoColor
            
            # 确保目标目录存在
            if (-not (Test-Path "$ReleaseDir")) {
                New-Item -ItemType Directory -Path "$ReleaseDir" -Force | Out-Null
            }
            
            # 如果文件已存在，删除它
            if (Test-Path "$ReleaseDir/xui-linux-$Arch.tar.gz") {
                Remove-Item -Force "$ReleaseDir/xui-linux-$Arch.tar.gz"
            }
            
            # 为了避免路径问题，创建一个用于 tar 的临时目录，确保文件结构正确
            $TarTempDir = "tar-temp-$Arch"
            if (Test-Path $TarTempDir) {
                Remove-Item -Recurse -Force $TarTempDir
            }
            New-Item -ItemType Directory -Path "$TarTempDir/xui/bin" -Force | Out-Null
            
            # 复制文件到临时目录
            Copy-Item -Path "$TempDir/xui" -Destination "$TarTempDir/xui/"
            Get-ChildItem -Path "$TempDir" -File | Where-Object { $_.Name -ne "xui" } | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination "$TarTempDir/xui/"
            }
            Copy-Item -Path "$TempDir/bin/*" -Destination "$TarTempDir/xui/bin/"
            
            # 使用 tar 创建 tar.gz 文件
            $CurrentDir = Get-Location
            Set-Location -Path $TarTempDir
            & tar -czf "../$ReleaseDir/xui-linux-$Arch.tar.gz" *
            Set-Location -Path $CurrentDir
            
            # 清理临时目录
            Remove-Item -Recurse -Force $TarTempDir
            
            Write-Host "  Created tar.gz package successfully" -ForegroundColor $SuccessColor
        } else {
            Write-Host "  tar command not found, skipping tar.gz package" -ForegroundColor $ErrorColor
        }
    } catch {
        Write-Host "  Error creating tar.gz package: $_" -ForegroundColor $ErrorColor
    }
    
    # 创建 zip 包
    try {
        # 如果文件已存在，删除它
        if (Test-Path "$ReleaseDir/xui-linux-$Arch.zip") {
            Remove-Item -Force "$ReleaseDir/xui-linux-$Arch.zip"
        }
        
        # 创建临时目录用于 zip 创建
        $ZipTempDir = "zip-temp-$Arch"
        if (Test-Path $ZipTempDir) {
            Remove-Item -Recurse -Force $ZipTempDir
        }
        New-Item -ItemType Directory -Path "$ZipTempDir/xui/bin" -Force | Out-Null
        
        # 复制文件到临时目录 (使用扁平结构更安全)
        Copy-Item -Path "$TempDir/xui" -Destination "$ZipTempDir/xui/"
        Get-ChildItem -Path "$TempDir" -File | Where-Object { $_.Name -ne "xui" } | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "$ZipTempDir/xui/"
        }
        Copy-Item -Path "$TempDir/bin/*" -Destination "$ZipTempDir/xui/bin/"
        
        # 检查是否安装了 7-Zip
        $SevenZipPath = "$env:ProgramFiles/7-Zip/7z.exe"
        $SevenZipPathx86 = "${env:ProgramFiles(x86)}/7-Zip/7z.exe"
        
        if (Test-Path $SevenZipPath) {
            Write-Host "  Using 7-Zip to create package with proper path separators" -ForegroundColor $SuccessColor
            # 使用 7-Zip 创建 zip (保留 Unix 风格路径分隔符)
            & $SevenZipPath a -tzip "$ReleaseDir/xui-linux-$Arch.zip" "$ZipTempDir\*" -mx9 -sccUTF-8
        } elseif (Test-Path $SevenZipPathx86) {
            Write-Host "  Using 7-Zip (x86) to create package with proper path separators" -ForegroundColor $SuccessColor
            # 使用 7-Zip (x86) 创建 zip (保留 Unix 风格路径分隔符)
            & $SevenZipPathx86 a -tzip "$ReleaseDir/xui-linux-$Arch.zip" "$ZipTempDir\*" -mx9 -sccUTF-8
        } else {
            Write-Host "  7-Zip not found, using built-in compression (WARNING: may not preserve path separators)" -ForegroundColor $ErrorColor
            
            # 使用 .NET 的 ZipFile 类创建 zip 包
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::CreateFromDirectory("$ZipTempDir", "$ReleaseDir/xui-linux-$Arch.zip", [System.IO.Compression.CompressionLevel]::Optimal, $false)
        }
        
        # 清理临时目录
        Remove-Item -Recurse -Force $ZipTempDir
        
        # 尝试验证 ZIP 文件
        if (Get-Command unzip -ErrorAction SilentlyContinue) {
            Write-Host "  Verifying ZIP file for path separators..." -ForegroundColor $InfoColor
            $output = unzip -l "$ReleaseDir/xui-linux-$Arch.zip" | Out-String
            if ($output -match "\\") {
                Write-Host "  Warning: Backslashes detected in ZIP file!" -ForegroundColor $ErrorColor
            } else {
                Write-Host "  ZIP file looks good - no backslashes detected" -ForegroundColor $SuccessColor
            }
        } else {
            Write-Host "  unzip command not available to verify path separators" -ForegroundColor $ErrorColor
        }
    } catch {
        Write-Host "  Error creating ZIP package: $_" -ForegroundColor $ErrorColor
    }
    
    # 清理
    Remove-Item -Recurse -Force $TempDir
    
    Write-Host "$Arch version packaging completed" -ForegroundColor $SuccessColor
}

# 检查 Go 环境
try {
    $null = Get-Command go -ErrorAction Stop
} catch {
    Write-Host "Error: Go environment not found. Please install Go first." -ForegroundColor $ErrorColor
    exit 1
}

# 主循环 - 构建每种架构
foreach ($Arch in $Architectures) {
    Build-Xui -Arch $Arch
}

# 显示发布信息
Write-Host "All versions compiled!" -ForegroundColor $SuccessColor
Write-Host "Release files are in the $ReleaseDir directory" -ForegroundColor $InfoColor
Write-Host ""
Get-ChildItem -Path $ReleaseDir | ForEach-Object {
    $FileSize = "{0:N0}" -f $_.Length
    Write-Host "$($_.Name)" -ForegroundColor $SuccessColor -NoNewline
    Write-Host " $FileSize" -ForegroundColor $DefaultColor
} 