# Simple PowerShell build script for xui
$VERSION = "1.0.0"
$RELEASE_DIR = "release"

# Create release directory
if (-not (Test-Path $RELEASE_DIR)) {
    New-Item -ItemType Directory -Path $RELEASE_DIR -Force | Out-Null
}

Write-Host "Creating release directory: $RELEASE_DIR" -ForegroundColor Green

# Supported architectures
$ARCHS = @("amd64", "arm64")

# Build and package each architecture
foreach ($ARCH in $ARCHS) {
    Write-Host "Building $ARCH version..." -ForegroundColor Blue
    
    # Set environment variables
    $env:GOOS = "linux"
    $env:GOARCH = $ARCH
    
    # Build main program
    Write-Host "Compiling main program..." -ForegroundColor Yellow
    go build -o "xui-$ARCH" main.go
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed!" -ForegroundColor Red
        exit 1
    }
    
    # Create temporary directory structure with forward slashes
    $TEMP_DIR = "temp-$ARCH"
    Remove-Item -Force -Recurse $TEMP_DIR -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path "$TEMP_DIR/bin" -Force | Out-Null
    
    # Copy files
    Copy-Item -Path "xui-$ARCH" -Destination "$TEMP_DIR/xui"
    Copy-Item -Path "bin/geoip.dat" -Destination "$TEMP_DIR/bin/" -ErrorAction SilentlyContinue
    Copy-Item -Path "bin/geosite.dat" -Destination "$TEMP_DIR/bin/" -ErrorAction SilentlyContinue
    Copy-Item -Path "bin/xray-linux-$ARCH" -Destination "$TEMP_DIR/bin/" -ErrorAction SilentlyContinue
    Copy-Item -Path "install.sh" -Destination "$TEMP_DIR/" -ErrorAction SilentlyContinue
    Copy-Item -Path "xui.service" -Destination "$TEMP_DIR/" -ErrorAction SilentlyContinue
    Copy-Item -Path "xui.sh" -Destination "$TEMP_DIR/" -ErrorAction SilentlyContinue
    
    # Convert text files to Unix format (LF line endings)
    Get-ChildItem -Path "$TEMP_DIR" -Recurse -File | Where-Object { $_.Extension -in ".sh", ".service" } | ForEach-Object {
        $content = Get-Content -Path $_.FullName -Raw
        if ($content) {
            $content = $content -replace "`r`n", "`n"
            Set-Content -Path $_.FullName -Value $content -NoNewline
            Write-Host "  Converted $($_.Name) to Unix format" -ForegroundColor Gray
        }
    }
    
    # Create packages using 7-Zip with forward slashes
    Write-Host "Creating packages..." -ForegroundColor Yellow
    
    # Use 7-Zip if available (highly recommended for proper path handling)
    if (Get-Command "7z" -ErrorAction SilentlyContinue) {
        # Create tar.gz package
        $CURRENT_DIR = Get-Location
        Set-Location $TEMP_DIR
        
        # Store the current directory in a variable for later use
        $FULL_PATH = (Get-Location).Path
        
        # Create a file list with corrected paths (forward slashes)
        $fileList = Get-ChildItem -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($FULL_PATH.Length + 1)
            # Replace backslashes with forward slashes
            $relativePath.Replace("\", "/")
        }
        
        # Write the file list to a temporary file
        $fileList | Out-File -FilePath "../files.txt" -Encoding utf8
        Set-Location ..
        
        # Create zip with proper paths
        Write-Host "  Creating ZIP with fixed path separators..." -ForegroundColor Yellow
        7z a -tzip "$RELEASE_DIR/xui-linux-$ARCH.zip" "@files.txt" -w$TEMP_DIR -mx=9
        
        # Clean up the file list
        Remove-Item -Force "files.txt" -ErrorAction SilentlyContinue
        
        # Also create tar.gz for Linux users
        Write-Host "  Creating TAR.GZ archive..." -ForegroundColor Yellow
        7z a -ttar "xui-linux-$ARCH.tar" "$TEMP_DIR/*"
        7z a -tgzip "$RELEASE_DIR/xui-linux-$ARCH.tar.gz" "xui-linux-$ARCH.tar"
        Remove-Item -Force "xui-linux-$ARCH.tar" -ErrorAction SilentlyContinue
    } else {
        # Fallback to built-in compression
        Write-Host "  7-Zip not found, using built-in compression (WARNING: may not preserve path separators)" -ForegroundColor Red
        Compress-Archive -Path "$TEMP_DIR/*" -DestinationPath "$RELEASE_DIR/xui-linux-$ARCH.zip" -Force
    }
    
    # Test the created ZIP file
    Write-Host "  Verifying ZIP file for path separators..." -ForegroundColor Yellow
    if (Get-Command "7z" -ErrorAction SilentlyContinue) {
        $output = & 7z l "$RELEASE_DIR/xui-linux-$ARCH.zip" | Out-String
        if ($output -match "\\\\") {
            Write-Host "  WARNING: Backslashes detected in ZIP file" -ForegroundColor Red
        } else {
            Write-Host "  ZIP file looks good - no backslashes detected" -ForegroundColor Green
        }
    }
    
    # Cleanup
    Remove-Item -Path "xui-$ARCH" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "$ARCH version packaging completed" -ForegroundColor Green
}

Write-Host "All versions compiled!" -ForegroundColor Green
Write-Host "Release files are in the $RELEASE_DIR directory" -ForegroundColor Cyan
Get-ChildItem -Path $RELEASE_DIR | Format-Table Name, Length 