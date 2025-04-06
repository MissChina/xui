#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Version setting
VERSION="1.0.0"
echo -e "${BLUE}Starting to build xui v${VERSION}${NC}"

# Create release directory
RELEASE_DIR="release"
mkdir -p "$RELEASE_DIR"
echo -e "${GREEN}Created release directory: $RELEASE_DIR${NC}"

# Supported architectures
ARCHS=("amd64" "arm64")

# Build function
build() {
    local arch=$1
    echo -e "${BLUE}Building ${arch} version...${NC}"
    
    # Create temporary build directory
    local temp_dir="temp-$arch"
    mkdir -p "$temp_dir/bin"
    
    # Set environment variables for Go
    export GOOS=linux
    export GOARCH=$arch
    
    # Build main program
    echo -e "${YELLOW}Compiling main program...${NC}"
    go build -o "$temp_dir/xui" main.go
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Build failed!${NC}"
        exit 1
    fi
    
    # Copy files - using forward slashes for paths
    echo -e "${YELLOW}Copying files...${NC}"
    
    # Copy Xray binaries
    if [ -f "bin/xray-linux-${arch}" ]; then
        cp "bin/xray-linux-${arch}" "$temp_dir/bin/"
    else
        echo -e "${RED}Warning: bin/xray-linux-${arch} not found${NC}"
    fi
    
    # Copy GeoIP data
    cp -f "bin/geoip.dat" "$temp_dir/bin/" 2>/dev/null || echo -e "${RED}Warning: bin/geoip.dat not found${NC}"
    cp -f "bin/geosite.dat" "$temp_dir/bin/" 2>/dev/null || echo -e "${RED}Warning: bin/geosite.dat not found${NC}"
    
    # Copy scripts and configuration files
    cp -f "install.sh" "$temp_dir/" 2>/dev/null || echo -e "${RED}Warning: install.sh not found${NC}"
    cp -f "xui.service" "$temp_dir/" 2>/dev/null || echo -e "${RED}Warning: xui.service not found${NC}"
    cp -f "xui.sh" "$temp_dir/" 2>/dev/null || echo -e "${RED}Warning: xui.sh not found${NC}"
    
    # Fix permissions
    chmod +x "$temp_dir/xui"
    chmod +x "$temp_dir/"*.sh 2>/dev/null
    chmod +x "$temp_dir/bin/"* 2>/dev/null
    
    # Create tar.gz package (using Unix-style paths)
    echo -e "${YELLOW}Creating tar.gz package...${NC}"
    tar -czf "$RELEASE_DIR/xui-linux-${arch}.tar.gz" -C "$(dirname "$temp_dir")" "$(basename "$temp_dir")"
    
    # Create zip package (using Unix-style paths)
    echo -e "${YELLOW}Creating zip package...${NC}"
    if command -v zip &> /dev/null; then
        (cd "$(dirname "$temp_dir")" && zip -r "../$RELEASE_DIR/xui-linux-${arch}.zip" "$(basename "$temp_dir")")
    else
        echo -e "${RED}Warning: zip command not found, skipping zip package${NC}"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}${arch} version packaging completed${NC}"
}

# Check Go environment
if ! command -v go &> /dev/null; then
    echo -e "${RED}Error: Go environment not found. Please install Go first.${NC}"
    exit 1
fi

# Main loop - build each architecture
for arch in "${ARCHS[@]}"; do
    build "$arch"
done

# Display release information
echo -e "${GREEN}All versions built successfully!${NC}"
echo -e "${BLUE}Release files are in the $RELEASE_DIR directory${NC}"
echo -e "${YELLOW}Generated files:${NC}"
ls -lh "$RELEASE_DIR" 