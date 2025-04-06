# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Define colors
$RED = [ConsoleColor]::Red
$GREEN = [ConsoleColor]::Green
$YELLOW = [ConsoleColor]::Yellow
$BLUE = [ConsoleColor]::Blue

# Function to log messages
function Write-Log {
    param (
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to create missing files
function Create-MissingFiles {
    Write-Log "Checking and creating necessary files..." $BLUE
    
    # Create bin directory if it doesn't exist
    if (-not (Test-Path "bin")) {
        Write-Log "Creating bin directory..." $YELLOW
        New-Item -ItemType Directory -Path "bin" -Force | Out-Null
    }
    
    # Create go.mod if it doesn't exist
    if (-not (Test-Path "go.mod")) {
        Write-Log "Creating go.mod file..." $YELLOW
        @"
module github.com/MissChina/xui

go 1.18

require (
    github.com/gin-gonic/gin v1.7.7
    github.com/goccy/go-json v0.9.4
    github.com/op/go-logging v0.0.0-20160315200505-970db520ece7
    github.com/robfig/cron/v3 v3.0.1
    github.com/shirou/gopsutil v3.21.11+incompatible
    github.com/xtls/xray-core v1.5.4
    golang.org/x/crypto v0.0.0-20220214200702-86341886e292
    gorm.io/driver/sqlite v1.3.1
    gorm.io/gorm v1.23.2
)
"@ | Out-File -FilePath "go.mod" -Encoding utf8
    }
    
    # Create main.go if it doesn't exist
    if (-not (Test-Path "main.go")) {
        Write-Log "Creating main.go file..." $YELLOW
        @"
package main

import (
    "fmt"
    "log"
    "os"
    "os/signal"
    "syscall"
)

func main() {
    fmt.Println("Starting xui...")
    
    // Setup signal handling for graceful shutdown
    sigs := make(chan os.Signal, 1)
    done := make(chan bool, 1)
    signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
    
    go func() {
        sig := <-sigs
        fmt.Println()
        fmt.Println("Received signal:", sig)
        done <- true
    }()
    
    fmt.Println("xui is running. Press Ctrl+C to exit.")
    <-done
    fmt.Println("Exiting xui...")
}
"@ | Out-File -FilePath "main.go" -Encoding utf8
    }
    
    # Create xui.service if it doesn't exist
    if (-not (Test-Path "xui.service")) {
        Write-Log "Creating xui.service file..." $YELLOW
        @"
[Unit]
Description=xui Service
After=network.target
Wants=network.target

[Service]
Type=simple
WorkingDirectory=/usr/local/xui/
ExecStart=/usr/local/xui/xui
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
"@ | Out-File -FilePath "xui.service" -Encoding utf8
    }
    
    # Create xui.sh if it doesn't exist
    if (-not (Test-Path "xui.sh")) {
        Write-Log "Creating xui.sh file..." $YELLOW
        @"
#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Check if user is root
if [[ \$EUID -ne 0 ]]; then
    echo -e "\${red}Error: This script must be run as root!\${plain}"
    exit 1
fi

# Detect architecture
arch=\$(uname -m)
if [[ \$arch == "x86_64" || \$arch == "x64" || \$arch == "amd64" ]]; then
    arch="amd64"
elif [[ \$arch == "aarch64" || \$arch == "arm64" ]]; then
    arch="arm64"
else
    echo -e "\${red}Unsupported architecture: \$arch\${plain}"
    exit 1
fi

# Show usage
show_usage() {
    echo -e "\${green}xui management script\${plain}"
    echo -e "Usage: xui [option]"
    echo -e "Options:"
    echo -e "  start        - Start xui service"
    echo -e "  stop         - Stop xui service"
    echo -e "  restart      - Restart xui service"
    echo -e "  status       - Check xui status"
    echo -e "  enable       - Enable xui service at boot"
    echo -e "  disable      - Disable xui service at boot"
    echo -e "  log          - View xui logs"
    echo -e "  update       - Update xui"
    echo -e "  uninstall    - Uninstall xui"
}

# Show menu
show_menu() {
    echo -e "\${green}xui panel management\${plain}"
    echo -e "  \${green}1.\${plain} Start xui"
    echo -e "  \${green}2.\${plain} Stop xui"
    echo -e "  \${green}3.\${plain} Restart xui"
    echo -e "  \${green}4.\${plain} Check xui status"
    echo -e "  \${green}5.\${plain} Enable xui at boot"
    echo -e "  \${green}6.\${plain} Disable xui at boot"
    echo -e "  \${green}7.\${plain} View xui logs"
    echo -e "  \${green}8.\${plain} Update xui"
    echo -e "  \${green}9.\${plain} Uninstall xui"
    echo -e "  \${green}0.\${plain} Exit"
    read -p "Please enter an option [0-9]: " option
    case \$option in
        0) exit 0 ;;
        1) systemctl start xui ;;
        2) systemctl stop xui ;;
        3) systemctl restart xui ;;
        4) systemctl status xui -l ;;
        5) systemctl enable xui ;;
        6) systemctl disable xui ;;
        7) journalctl -u xui --no-pager -n 100 ;;
        8) bash <(curl -Ls https://raw.githubusercontent.com/MissChina/xui/master/install.sh) ;;
        9) bash <(curl -Ls https://raw.githubusercontent.com/MissChina/xui/master/install.sh) uninstall ;;
        *) echo -e "\${red}Invalid option\${plain}" ;;
    esac
}

# Main
if [[ \$# -gt 0 ]]; then
    case \$1 in
        start) systemctl start xui ;;
        stop) systemctl stop xui ;;
        restart) systemctl restart xui ;;
        status) systemctl status xui -l ;;
        enable) systemctl enable xui ;;
        disable) systemctl disable xui ;;
        log) journalctl -u xui --no-pager -n 100 ;;
        update) bash <(curl -Ls https://raw.githubusercontent.com/MissChina/xui/master/install.sh) ;;
        uninstall) bash <(curl -Ls https://raw.githubusercontent.com/MissChina/xui/master/install.sh) uninstall ;;
        *) show_usage ;;
    esac
else
    show_menu
fi
"@ | Out-File -FilePath "xui.sh" -Encoding utf8
    }
    
    # Create install.sh if it doesn't exist
    if (-not (Test-Path "install.sh")) {
        Write-Log "Creating install.sh file..." $YELLOW
        @"
#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Check if user is root
if [[ \$EUID -ne 0 ]]; then
    echo -e "\${red}Error: This script must be run as root!\${plain}"
    exit 1
fi

# Get latest release
github_url="https://github.com/MissChina/xui"
latest_version=\$(curl -Ls "https://api.github.com/repos/MissChina/xui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [[ ! -n "\$latest_version" ]]; then
    echo -e "\${red}Failed to fetch latest version, please check your network\${plain}"
    exit 1
fi

# Detect architecture
arch=\$(uname -m)
if [[ \$arch == "x86_64" || \$arch == "x64" || \$arch == "amd64" ]]; then
    arch="amd64"
elif [[ \$arch == "aarch64" || \$arch == "arm64" ]]; then
    arch="arm64"
else
    echo -e "\${red}Unsupported architecture: \$arch\${plain}"
    exit 1
fi

# Install xui
install_x_ui() {
    systemctl stop xui 2>/dev/null
    
    # Download latest version
    echo -e "\${green}Downloading xui v\$latest_version for \$arch...\${plain}"
    wget -N --no-check-certificate -O /usr/local/xui-linux-\$arch.zip \${github_url}/releases/download/\${latest_version}/xui-linux-\$arch.zip
    if [[ \$? -ne 0 ]]; then
        echo -e "\${red}Failed to download xui, please check your network\${plain}"
        exit 1
    fi

    # Install unzip if not exist
    if ! command -v unzip >/dev/null 2>&1; then
        echo -e "\${green}Installing unzip...\${plain}"
        if command -v apt >/dev/null 2>&1; then
            apt update && apt install -y unzip
        elif command -v yum >/dev/null 2>&1; then
            yum install -y unzip
        else
            echo -e "\${red}Failed to install unzip, please install it manually\${plain}"
            exit 1
        fi
    fi

    # Extract and install
    echo -e "\${green}Installing xui...\${plain}"
    rm -rf /usr/local/xui
    mkdir -p /usr/local/xui
    unzip -o /usr/local/xui-linux-\$arch.zip -d /usr/local/xui
    if [[ \$? -ne 0 ]]; then
        echo -e "\${red}Failed to extract xui, please check your disk space and permissions\${plain}"
        exit 1
    fi
    
    # Set permissions
    chmod +x /usr/local/xui/xui
    chmod +x /usr/local/xui/bin/xray-linux-*
    chmod +x /usr/local/xui/xui.sh
    
    # Create symbolic link
    ln -sf /usr/local/xui/xui.sh /usr/bin/xui
    
    # Install service
    cp -f /usr/local/xui/xui.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable xui
    systemctl start xui
    
    # Cleanup
    rm -f /usr/local/xui-linux-\$arch.zip
    
    echo -e "\${green}xui v\$latest_version installed successfully\${plain}"
    echo -e ""
    echo -e "Panel access: \${green}http://your-server-ip:54321\${plain}"
    echo -e "Username: \${green}admin\${plain}"
    echo -e "Password: \${green}admin\${plain}"
    echo -e ""
    echo -e "To manage xui: \${green}xui\${plain}"
}

# Uninstall xui
uninstall_x_ui() {
    echo -e "\${yellow}Are you sure you want to uninstall xui? (y/n)\${plain}"
    read -p "(default: n): " confirm
    if [[ \$confirm != "y" ]]; then
        echo -e "\${green}Cancelled\${plain}"
        return
    fi
    
    systemctl stop xui
    systemctl disable xui
    rm -rf /usr/local/xui
    rm -f /usr/bin/xui
    rm -f /etc/systemd/system/xui.service
    systemctl daemon-reload
    
    echo -e "\${green}xui uninstalled successfully\${plain}"
}

# Show usage
show_usage() {
    echo -e "Usage: \${green}bash install.sh [option]\${plain}"
    echo -e "Options:"
    echo -e "  install    - Install xui"
    echo -e "  uninstall  - Uninstall xui"
    echo -e "  help       - Show this help"
}

# Main
if [[ \$# -gt 0 ]]; then
    case \$1 in
        install) install_x_ui ;;
        uninstall) uninstall_x_ui ;;
        help) show_usage ;;
        *) show_usage ;;
    esac
else
    install_x_ui
fi
"@ | Out-File -FilePath "install.sh" -Encoding utf8
    }
    
    Write-Log "All necessary files have been created or checked." $GREEN
}

# Function to prepare build environment
function Prepare-BuildEnvironment {
    $tempDir = Join-Path $env:TEMP "xui-build"
    $releaseDir = "release"
    
    # Clean old directories
    Write-Log "Cleaning build environment..." $BLUE
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    if (Test-Path $releaseDir) {
        Remove-Item -Path $releaseDir -Recurse -Force
    }
    
    # Create directories
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
    
    return @{
        TempDir = $tempDir
        ReleaseDir = $releaseDir
    }
}

# Function to build xui for a specific architecture
function Build-XUI {
    param (
        [string]$Architecture,
        [string]$OutputDir
    )
    
    Write-Log "Building for $Architecture..." $BLUE
    
    # Set environment variables
    $env:GOOS = "linux"
    $env:GOARCH = $Architecture
    $env:CGO_ENABLED = "0"
    
    # Create architecture-specific directory
    $archDir = Join-Path $OutputDir $Architecture
    New-Item -ItemType Directory -Path $archDir -Force | Out-Null
    
    try {
        # Build xui binary
        Write-Log "Compiling xui..." $YELLOW
        & go build -o "$archDir/xui" -ldflags "-s -w" .
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to build xui" $RED
            return $false
        }
        
        # Copy required files
        Write-Log "Copying required files..." $YELLOW
        Copy-Item -Path "bin" -Destination $archDir -Recurse
        Copy-Item -Path "xui.service" -Destination $archDir
        Copy-Item -Path "xui.sh" -Destination $archDir
        Copy-Item -Path "install.sh" -Destination $archDir
        
        Write-Log "Build for $Architecture completed successfully" $GREEN
        return $true
    }
    catch {
        Write-Log "Error during build: $_" $RED
        return $false
    }
}

# Function to create release packages
function Create-ReleasePackage {
    param (
        [string]$Architecture,
        [string]$SourceDir,
        [string]$OutputDir
    )
    
    Write-Log "Creating release package for $Architecture..." $BLUE
    
    try {
        $zipFile = Join-Path $OutputDir "xui-linux-$Architecture.zip"
        Compress-Archive -Path "$SourceDir/$Architecture/*" -DestinationPath $zipFile -Force
        Write-Log "Package created: $zipFile" $GREEN
        return $true
    }
    catch {
        Write-Log "Error creating package: $_" $RED
        return $false
    }
}

# Main function
function Start-Build {
    Write-Log "Starting xui build process..." $GREEN
    
    # Create or verify necessary files
    Create-MissingFiles
    
    # Prepare build environment
    $env = Prepare-BuildEnvironment
    $tempDir = $env.TempDir
    $releaseDir = $env.ReleaseDir
    
    # Try to detect Go
    try {
        $goVersion = & go version
        Write-Log "Detected Go: $goVersion" $GREEN
        
        # Build for each architecture
        foreach ($arch in @("amd64", "arm64")) {
            if (Build-XUI -Architecture $arch -OutputDir $tempDir) {
                Create-ReleasePackage -Architecture $arch -SourceDir $tempDir -OutputDir $releaseDir
            }
        }
    }
    catch {
        Write-Log "Go is not installed or not in PATH" $RED
        Write-Log "Please install Go first" $YELLOW
        exit 1
    }
    
    # Clean up
    Write-Log "Cleaning up temporary files..." $BLUE
    Remove-Item -Path $tempDir -Recurse -Force
    
    # Show results
    Write-Log "Build process completed!" $GREEN
    Write-Log "Release packages:" $GREEN
    Get-ChildItem $releaseDir | ForEach-Object {
        Write-Log "- $($_.Name)" $YELLOW
    }
}

# Start the build process
Start-Build 