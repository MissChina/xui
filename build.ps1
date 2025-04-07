# PowerShell build script for xui
# 此脚本用于在 Windows 环境下构建 xui 的 Linux 发布版本

# 设置颜色
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Yellow"
$DefaultColor = "White"
$WarningColor = "Magenta"

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

# 处理文本文件并确保正确的编码和行结束符
function Process-TextFile($source, $destination) {
    try {
        # 读取文件内容 - 直接用System.IO读取字节
        $content = Get-Content -Path $source -Raw -Encoding UTF8
        
        # 替换Windows的CRLF为Unix的LF
        $content = $content.Replace("`r`n", "`n")
        
        # 使用UTF-8编码(不带BOM)写入目标文件
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($destination, $content, $utf8NoBom)
        
        # 输出信息
        Write-Host "  Processed file $source to $destination with UTF-8 encoding (no BOM) and Unix line endings"
    }
    catch {
        Write-Host "  Error processing file $source" -ForegroundColor $ErrorColor
    }
}

# 复制文件函数 - 对于文本文件进行编码处理
function Copy-File-With-Encoding($source, $destination) {
    if (Test-Path $source) {
        # 创建目标目录（如果不存在）
        $destDir = Split-Path -Parent $destination
        if (!(Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        # 检查文件类型
        $extension = [System.IO.Path]::GetExtension($source)
        
        # 对于文本文件进行处理
        if ($extension -in ".sh", ".service") {
            Process-TextFile -source $source -destination $destination
        }
        else {
            # 二进制文件直接复制
            Copy-Item -Path $source -Destination $destination -Force
            Write-Host "  Copied binary file $source to $destination"
        }
    }
    else {
        Write-Host "  Warning: $source not found" -ForegroundColor $WarningColor
    }
}

# 创建包含文件目录结构
function Create-Package-Structure($targetDir, $sourceDir) {
    # 创建必要目录
    New-Item -ItemType Directory -Path "$targetDir/xui/bin" -Force | Out-Null
    
    # 复制主程序
    Copy-Item -Path "$sourceDir/xui/xui" -Destination "$targetDir/xui/" -Force
    
    # 复制脚本和服务文件
    foreach ($file in @("install.sh", "xui.sh", "xui.service")) {
        if (Test-Path "$sourceDir/xui/$file") {
            Copy-Item -Path "$sourceDir/xui/$file" -Destination "$targetDir/xui/" -Force
        }
    }
    
    # 复制bin目录下的所有文件
    if (Test-Path "$sourceDir/xui/bin") {
        Get-ChildItem -Path "$sourceDir/xui/bin" | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "$targetDir/xui/bin/" -Force
        }
    }
}

# 构建函数
function Build($arch) {
    # 创建临时目录
    $TempDir = "temp_build_$arch"
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path "$TempDir/xui/bin" | Out-Null
    
    Write-Host "Compiling main program..." -ForegroundColor $InfoColor
    # 编译应用程序
    $env:GOOS="linux"
    $env:GOARCH=$arch
    & go build -o "$TempDir/xui/xui" -trimpath -ldflags "-s -w" .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to compile program for $arch architecture" -ForegroundColor $ErrorColor
        return
    }
    
    Write-Host "Copying files..." -ForegroundColor $InfoColor
    
    # 复制脚本和配置文件到临时目录的xui子目录下
    foreach ($file in @("install.sh", "xui.sh", "xui.service")) {
        if (Test-Path $file) {
            Copy-File-With-Encoding -source $file -destination "$TempDir/xui/$file"
            Write-Host "  Copied $file to $TempDir/xui/"
        } else {
            Write-Host "Warning: $file not found" -ForegroundColor $WarningColor
        }
    }
    
    # 复制 Xray 二进制文件
    $XrayFilePath = "bin/xray-linux-$arch"
    if (Test-Path $XrayFilePath) {
        Copy-Item $XrayFilePath -Destination "$TempDir/xui/bin/" -Force
    } else {
        Write-Host "Warning: $XrayFilePath not found" -ForegroundColor $WarningColor
    }
    
    # 复制 geo 文件
    foreach ($file in @("geoip.dat", "geosite.dat")) {
        $GeoFilePath = "bin/$file"
        if (Test-Path $GeoFilePath) {
            Copy-Item $GeoFilePath -Destination "$TempDir/xui/bin/" -Force
        } else {
            Write-Host "Warning: $GeoFilePath not found" -ForegroundColor $WarningColor
        }
    }
    
    # 创建打包文件
    Write-Host "Creating packages..." -ForegroundColor $InfoColor
    
    # 创建 tar.gz 包
    Write-Host "  Creating tar.gz package..." -ForegroundColor $InfoColor
    try {
        # 如果文件已存在，删除它
        if (Test-Path "$ReleaseDir/xui-linux-$arch.tar.gz") {
            Remove-Item -Force "$ReleaseDir/xui-linux-$arch.tar.gz"
        }
        
        # 为了避免路径问题，创建一个用于 tar 的临时目录，确保文件结构正确
        $TarTempDir = "tar-temp-$arch"
        if (Test-Path $TarTempDir) {
            Remove-Item -Recurse -Force $TarTempDir
        }
        New-Item -ItemType Directory -Path $TarTempDir -Force | Out-Null
        
        # 使用通用方法创建包结构
        Create-Package-Structure -targetDir $TarTempDir -sourceDir $TempDir
        
        # 使用 tar 创建 tar.gz 文件
        $CurrentDir = Get-Location
        Set-Location -Path $TarTempDir
        & tar -czf "../$ReleaseDir/xui-linux-$arch.tar.gz" *
        Set-Location -Path $CurrentDir
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Created tar.gz package successfully" -ForegroundColor $SuccessColor
        } else {
            Write-Host "  Failed to create tar.gz package" -ForegroundColor $ErrorColor
        }
        
        # 清理临时目录
        Remove-Item -Recurse -Force $TarTempDir
    } catch {
        Write-Host "  Error creating tar.gz package: $_" -ForegroundColor $ErrorColor
    }
    
    # 创建 zip 包
    try {
        # 如果文件已存在，删除它
        if (Test-Path "$ReleaseDir/xui-linux-$arch.zip") {
            Remove-Item -Force "$ReleaseDir/xui-linux-$arch.zip"
        }
        
        # 创建临时目录用于 zip 创建
        $ZipTempDir = "zip-temp-$arch"
        if (Test-Path $ZipTempDir) {
            Remove-Item -Recurse -Force $ZipTempDir
        }
        New-Item -ItemType Directory -Path $ZipTempDir -Force | Out-Null
        
        # 使用通用方法创建包结构
        Create-Package-Structure -targetDir $ZipTempDir -sourceDir $TempDir
        
        # 检查是否安装了 7-Zip
        $SevenZipPath = "$env:ProgramFiles/7-Zip/7z.exe"
        $SevenZipPathx86 = "${env:ProgramFiles(x86)}/7-Zip/7z.exe"
        
        if (Test-Path $SevenZipPath) {
            Write-Host "  Using 7-Zip to create package with proper path separators" -ForegroundColor $SuccessColor
            # 使用 7-Zip 创建 zip (保留 Unix 风格路径分隔符)
            & $SevenZipPath a -tzip "$ReleaseDir/xui-linux-$arch.zip" "$ZipTempDir\*" -mx9 -sccUTF-8
        } elseif (Test-Path $SevenZipPathx86) {
            Write-Host "  Using 7-Zip (x86) to create package with proper path separators" -ForegroundColor $SuccessColor
            # 使用 7-Zip (x86) 创建 zip (保留 Unix 风格路径分隔符)
            & $SevenZipPathx86 a -tzip "$ReleaseDir/xui-linux-$arch.zip" "$ZipTempDir\*" -mx9 -sccUTF-8
        } else {
            Write-Host "  7-Zip not found, using built-in compression (WARNING: may not preserve path separators)" -ForegroundColor $ErrorColor
            
            # 使用 .NET 的 ZipFile 类创建 zip 包
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::CreateFromDirectory("$ZipTempDir", "$ReleaseDir/xui-linux-$arch.zip", [System.IO.Compression.CompressionLevel]::Optimal, $false)
        }
        
        # 清理临时目录
        Remove-Item -Recurse -Force $ZipTempDir
        
        # 尝试验证 ZIP 文件
        if (Get-Command unzip -ErrorAction SilentlyContinue) {
            Write-Host "  Verifying ZIP file for path separators..." -ForegroundColor $InfoColor
            $output = unzip -l "$ReleaseDir/xui-linux-$arch.zip" | Out-String
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
    
    Write-Host "$arch version packaging completed" -ForegroundColor $SuccessColor
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
    Build -arch $Arch
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