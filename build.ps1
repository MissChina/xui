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

# 显示文件编码信息
function Show-FileEncoding($file) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $encoding = "Unknown"
        
        # 检测UTF-8 BOM
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $encoding = "UTF-8 with BOM"
        } 
        # 检测UTF-16 LE BOM
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            $encoding = "UTF-16 LE with BOM"
        }
        # 检测UTF-16 BE BOM
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            $encoding = "UTF-16 BE with BOM"
        }
        # 尝试检测UTF-8无BOM
        elseif ((Test-Utf8NoBom -Bytes $bytes)) {
            $encoding = "UTF-8 without BOM"
        }
        # 其他编码
        else {
            $encoding = "Possibly ANSI or other encoding"
        }
        
        Write-Host "  File $file encoding: $encoding"
        return $encoding
    } catch {
        Write-Host "  Error detecting encoding for $file" -ForegroundColor $ErrorColor
        return "Unknown"
    }
}

# 测试UTF-8无BOM编码
function Test-Utf8NoBom($Bytes) {
    # 简单的UTF-8序列检测
    $isPossiblyUtf8 = $true
    $i = 0
    while ($i -lt $Bytes.Length) {
        # 单字节ASCII字符
        if ($Bytes[$i] -lt 0x80) {
            $i++
            continue
        }
        # 检测2字节序列
        elseif (($Bytes[$i] -ge 0xC2) -and ($Bytes[$i] -le 0xDF)) {
            if (($i + 1 -lt $Bytes.Length) -and (($Bytes[$i+1] -ge 0x80) -and ($Bytes[$i+1] -le 0xBF))) {
                $i += 2
                continue
            }
        }
        # 检测3字节序列
        elseif (($Bytes[$i] -ge 0xE0) -and ($Bytes[$i] -le 0xEF)) {
            if (($i + 2 -lt $Bytes.Length) -and 
                (($Bytes[$i+1] -ge 0x80) -and ($Bytes[$i+1] -le 0xBF)) -and
                (($Bytes[$i+2] -ge 0x80) -and ($Bytes[$i+2] -le 0xBF))) {
                $i += 3
                continue
            }
        }
        # 检测4字节序列
        elseif (($Bytes[$i] -ge 0xF0) -and ($Bytes[$i] -le 0xF7)) {
            if (($i + 3 -lt $Bytes.Length) -and 
                (($Bytes[$i+1] -ge 0x80) -and ($Bytes[$i+1] -le 0xBF)) -and
                (($Bytes[$i+2] -ge 0x80) -and ($Bytes[$i+2] -le 0xBF)) -and
                (($Bytes[$i+3] -ge 0x80) -and ($Bytes[$i+3] -le 0xBF))) {
                $i += 4
                continue
            }
        }
        
        $isPossiblyUtf8 = $false
        break
    }
    
    return $isPossiblyUtf8
}

# 复制文件函数
function CopyWithEncoding($source, $destination) {
    if (Test-Path $source) {
        # 创建目标目录（如果不存在）
        $destDir = Split-Path -Parent $destination
        if (!(Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        try {
            # 检查文件类型
            $extension = [System.IO.Path]::GetExtension($source)
            
            # 文本文件需要编码转换
            if ($extension -in ".sh", ".service", ".txt", ".md") {
                # 检查源文件编码
                $encoding = Show-FileEncoding -file $source
                
                # 读取文件内容
                $bytes = [System.IO.File]::ReadAllBytes($source)
                $content = ""
                
                # 根据检测到的编码进行处理
                if ($encoding -eq "UTF-8 with BOM") {
                    $content = [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
                } elseif ($encoding -eq "UTF-16 LE with BOM") {
                    $content = [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
                } elseif ($encoding -eq "UTF-16 BE with BOM") {
                    $content = [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
                } else {
                    # 尝试以UTF-8读取
                    $content = [System.Text.Encoding]::UTF8.GetString($bytes)
                }
                
                # 保存为UTF-8无BOM格式
                [System.IO.File]::WriteAllText($destination, $content, [System.Text.UTF8Encoding]::new($false))
                
                # 验证目标文件
                Write-Host "  Copied $source to $destination with UTF-8 encoding"
                Show-FileEncoding -file $destination
            } else {
                # 二进制文件直接复制
                Copy-Item -Path $source -Destination $destination -Force
                Write-Host "  Copied binary file $source to $destination"
            }
        } catch {
            Write-Host "  Error copying $source" -ForegroundColor $ErrorColor
        }
    } else {
        Write-Host "Warning: $source not found" -ForegroundColor $WarningColor
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

# 将文件转换为Unix格式
function ConvertToUnix($file) {
    if (Test-Path $file) {
        try {
            # 读取文件内容
            $bytes = [System.IO.File]::ReadAllBytes($file)
            $encoding = Show-FileEncoding -file $file
            $content = ""
            
            # 根据检测到的编码进行处理
            if ($encoding -eq "UTF-8 with BOM") {
                $content = [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
            } elseif ($encoding -eq "UTF-16 LE with BOM") {
                $content = [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
            } elseif ($encoding -eq "UTF-16 BE with BOM") {
                $content = [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
            } else {
                # 尝试以UTF-8读取
                $content = [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            
            # 替换Windows的CRLF为Unix的LF
            $content = $content -replace "`r`n", "`n"
            
            # 使用UTF-8编码(不带BOM)保存文件
            [System.IO.File]::WriteAllText($file, $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  Converted $file to Unix format with UTF-8 encoding"
        } catch {
            Write-Host "  Error converting $file" -ForegroundColor $ErrorColor
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
            CopyWithEncoding -source $file -destination "$TempDir/xui/$file"
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
    
    # 确保所有文本文件使用 Unix 风格的行结束符和UTF-8编码
    Get-ChildItem -Path "$TempDir/xui" -Recurse -Include "*.sh", "*.service" | ForEach-Object {
        ConvertToUnix -file $_.FullName
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