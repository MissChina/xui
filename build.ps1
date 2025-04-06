# Simple PowerShell build script
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
    
    # Create temporary directory structure
    $TEMP_DIR = "temp-$ARCH"
    New-Item -ItemType Directory -Path "$TEMP_DIR/bin" -Force | Out-Null
    
    # Copy files
    Copy-Item -Path "xui-$ARCH" -Destination "$TEMP_DIR/xui"
    Copy-Item -Path "bin/geoip.dat" -Destination "$TEMP_DIR/bin/" -ErrorAction SilentlyContinue
    Copy-Item -Path "bin/geosite.dat" -Destination "$TEMP_DIR/bin/" -ErrorAction SilentlyContinue
    Copy-Item -Path "bin/xray-linux-$ARCH" -Destination "$TEMP_DIR/bin/" -ErrorAction SilentlyContinue
    Copy-Item -Path "install.sh" -Destination "$TEMP_DIR/" -ErrorAction SilentlyContinue
    Copy-Item -Path "xui.service" -Destination "$TEMP_DIR/" -ErrorAction SilentlyContinue
    Copy-Item -Path "xui.sh" -Destination "$TEMP_DIR/" -ErrorAction SilentlyContinue
    
    # Create package
    Write-Host "Creating package..." -ForegroundColor Yellow
    
    if (Get-Command "7z" -ErrorAction SilentlyContinue) {
        # Create zip package
        7z a -tzip "$RELEASE_DIR/xui-linux-$ARCH.zip" "$TEMP_DIR/*"
    } else {
        # Use built-in compression
        Compress-Archive -Path "$TEMP_DIR/*" -DestinationPath "$RELEASE_DIR/xui-linux-$ARCH.zip" -Force
    }
    
    # Cleanup
    Remove-Item -Path "xui-$ARCH" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "$ARCH version packaging completed" -ForegroundColor Green
}

Write-Host "All versions compiled!" -ForegroundColor Green
Write-Host "Release files are in the $RELEASE_DIR directory" -ForegroundColor Cyan
Get-ChildItem -Path $RELEASE_DIR | Format-Table Name, Length 