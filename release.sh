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
    
    # Create temporary build directory with a unique name
    local temp_dir="temp-$arch"
    rm -rf "$temp_dir"
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
    
    # Ensure all text files use Unix-style line endings
    find "$temp_dir" -type f -name "*.sh" -o -name "*.service" | xargs -r dos2unix -q 2>/dev/null
    
    # Create tar.gz package (using Unix-style paths)
    echo -e "${YELLOW}Creating tar.gz package...${NC}"
    tar -czf "$RELEASE_DIR/xui-linux-${arch}.tar.gz" -C "$(dirname "$temp_dir")" "$(basename "$temp_dir")" --transform "s|^$(basename "$temp_dir")|xui|"
    
    # Create zip package (using Unix-style paths)
    echo -e "${YELLOW}Creating zip package...${NC}"
    if command -v zip &> /dev/null; then
        # Create a temporary directory for zip creation
        local zip_temp="zip-temp-$arch"
        rm -rf "$zip_temp"
        mkdir -p "$zip_temp"
        
        # Copy files to temporary directory
        cp -r "$temp_dir"/* "$zip_temp/"
        
        # Change to temporary directory
        cd "$zip_temp" || exit
        
        # Create zip with forward slashes
        zip -r "../$RELEASE_DIR/xui-linux-${arch}.zip" . -x "*.DS_Store" "*.git*"
        
        # Go back and cleanup
        cd ..
        rm -rf "$zip_temp"
    else
        echo -e "${RED}Warning: zip command not found, skipping zip package${NC}"
    fi
    
    # Test the zip file for backslashes (if unzip is available)
    if command -v unzip &> /dev/null; then
        echo -e "${YELLOW}Verifying zip file for path separators...${NC}"
        unzip -l "$RELEASE_DIR/xui-linux-${arch}.zip" | grep -q "\\"
        if [ $? -eq 0 ]; then
            echo -e "${RED}Warning: Backslashes detected in zip file${NC}"
            # Try to fix the zip file
            echo -e "${YELLOW}Attempting to fix zip file...${NC}"
            local fix_temp="fix-temp-$arch"
            rm -rf "$fix_temp"
            mkdir -p "$fix_temp"
            
            # Extract with unzip
            unzip -o "$RELEASE_DIR/xui-linux-${arch}.zip" -d "$fix_temp"
            
            # Create new zip with forward slashes
            cd "$fix_temp" || exit
            zip -r "../$RELEASE_DIR/xui-linux-${arch}.zip.new" . -x "*.DS_Store" "*.git*"
            cd ..
            
            # Replace old zip with new one
            mv "$RELEASE_DIR/xui-linux-${arch}.zip.new" "$RELEASE_DIR/xui-linux-${arch}.zip"
            
            # Cleanup
            rm -rf "$fix_temp"
            
            # Verify again
            unzip -l "$RELEASE_DIR/xui-linux-${arch}.zip" | grep -q "\\"
            if [ $? -eq 0 ]; then
                echo -e "${RED}Failed to fix zip file${NC}"
            else
                echo -e "${GREEN}Successfully fixed zip file${NC}"
            fi
        else
            echo -e "${GREEN}Zip file looks good - no backslashes detected${NC}"
        fi
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

# Check for dos2unix
if ! command -v dos2unix &> /dev/null; then
    echo -e "${YELLOW}Warning: dos2unix not found, will attempt without line ending conversion${NC}"
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