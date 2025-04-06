package config

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

//go:embed version
var version string

//go:embed name
var name string

//go:embed default-config.json
var defaultConfig string

type LogLevel string

const (
	Debug LogLevel = "debug"
	Info  LogLevel = "info"
	Warn  LogLevel = "warn"
	Error LogLevel = "error"
)

func GetVersion() string {
	return strings.TrimSpace(version)
}

func GetName() string {
	return strings.TrimSpace(name)
}

func GetLogLevel() LogLevel {
	if IsDebug() {
		return Debug
	}
	logLevel := os.Getenv("XUI_LOG_LEVEL")
	if logLevel == "" {
		return Info
	}
	return LogLevel(logLevel)
}

func IsDebug() bool {
	return os.Getenv("XUI_DEBUG") == "true"
}

func GetDBPath() string {
	return fmt.Sprintf("/etc/%s/%s.db", GetName(), GetName())
}

func GetDefaultConfigPath() string {
	return fmt.Sprintf("/etc/%s/config.json", GetName())
}

func GetDefaultConfig() string {
	return defaultConfig
}

// EnsureConfigDir 确保配置目录存在
func EnsureConfigDir() error {
	configDir := fmt.Sprintf("/etc/%s", GetName())
	if _, err := os.Stat(configDir); os.IsNotExist(err) {
		err = os.MkdirAll(configDir, 0755)
		if err != nil {
			return err
		}
	}
	return nil
}

// InitConfig 初始化配置文件，如果不存在则创建默认配置
func InitConfig() error {
	err := EnsureConfigDir()
	if err != nil {
		return err
	}

	configPath := GetDefaultConfigPath()
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		// 创建logs目录
		logsDir := fmt.Sprintf("/etc/%s/logs", GetName())
		err = os.MkdirAll(logsDir, 0755)
		if err != nil {
			return err
		}

		// 写入默认配置
		err = ioutil.WriteFile(configPath, []byte(defaultConfig), 0644)
		if err != nil {
			return err
		}
	}

	return nil
}
