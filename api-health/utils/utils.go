package utils

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"os"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	"go.uber.org/automaxprocs/maxprocs"
	"gopkg.in/yaml.v2"
)

const (
	ERRORTEXT = "%s is unhealthy"
	ERRORICON = "❌"
)

// Settings 配置
type Settings struct {
	CheckInterval      int    `yaml:"check_interval"`
	CurlTimeout        int    `yaml:"curl_timeout"`
	ConnectTimeout     int    `yaml:"connect_timeout"`
	InspectionInterval string `yaml:"inspection_interval"` // 添加定时巡检配置字段
}

// Feishu 配置
type Feishu struct {
	WebhookURL      string `yaml:"webhook_url"`
	NotifyOnFailure bool   `yaml:"notify_on_failure"`
}

// Endpoint 端点配置
type Endpoint struct {
	Path   string `yaml:"path"`
	Apikey string `yaml:"apikey"`
}

// Service 服务配置
type Service struct {
	Endpoints []Endpoint `yaml:"endpoints"`
}

// SSL配置结构体
type SSLConfig struct {
	Domains []struct {
		URL  string `yaml:"url"`
		Port int    `yaml:"port"`
	} `yaml:"domains"`
}

// CertInfo SSL证书信息结构体
type CertInfo struct {
	CommonName    string    // 颁发给
	IssuerName    string    // 颁发者
	ExpiryDate    time.Time // 过期时间
	DaysRemaining float64   // 剩余天数
}

// 更新 Config 结构体，添加 SSL 字段
type Config struct {
	Settings Settings           `yaml:"settings"`
	Feishu   Feishu             `yaml:"feishu"`
	Services map[string]Service `yaml:"services"`
	SSL      SSLConfig          `yaml:"ssl"`
}

// CheckSSL 检查单个域名的 SSL 证书
func CheckSSL(domain string, port int, config *Config) (*CertInfo, error) {
	conn, err := tls.Dial("tcp", domain+":"+strconv.Itoa(port), &tls.Config{
		InsecureSkipVerify: true,
	})
	if err != nil {
		if config.Feishu.NotifyOnFailure {
			errMsg := fmt.Sprintf("域名 %s 的SSL证书检查失败: %v", domain, err)
			if err := SendFeishuMsg(config, errMsg); err != nil {
				fmt.Printf("❌ 发送飞书通知失败: %v\n", err)
			}
		}
		return nil, fmt.Errorf("SSL连接失败: %v", err)
	}
	defer conn.Close()

	cert := conn.ConnectionState().PeerCertificates[0]

	certInfo := &CertInfo{
		CommonName:    cert.Subject.CommonName,
		IssuerName:    cert.Issuer.CommonName,
		ExpiryDate:    cert.NotAfter,
		DaysRemaining: time.Until(cert.NotAfter).Hours() / 24,
	}

	// 如果证书将在30天内过期，发送飞书通知
	if certInfo.DaysRemaining < 30 && config.Feishu.NotifyOnFailure {
		warnMsg := fmt.Sprintf("⚠️ 警告：域名 %s 的SSL证书将在 %.0f 天后过期！\n证书信息:\n- 颁发给: %s\n- 颁发者: %s\n- 过期时间: %s",
			domain,
			certInfo.DaysRemaining,
			certInfo.CommonName,
			certInfo.IssuerName,
			certInfo.ExpiryDate.Format("2006-01-02 15:04:05"))
		if err := SendFeishuMsg(config, warnMsg); err != nil {
			fmt.Printf("❌ 发送飞书通知失败: %v\n", err)
		}
	}

	return certInfo, nil
}

// PrintCertInfo 打印证书信息
func (c *CertInfo) PrintCertInfo() {
	fmt.Printf("证书信息:\n")
	fmt.Printf("- 颁发给: %s\n", c.CommonName)
	fmt.Printf("- 颁发者: %s\n", c.IssuerName)
	fmt.Printf("- 过期时间: %s\n", c.ExpiryDate.Format("2006-01-02 15:04:05"))
	fmt.Printf("- 剩余天数: %.0f天\n", c.DaysRemaining)

	if c.DaysRemaining < 40 {
		fmt.Printf("⚠️ 警告：证书将在 %.0f 天后过期！\n", c.DaysRemaining)
	}
}

// InitConfig 从配置文件加载并解析配置
func InitConfig(configPath string) (*Config, error) {
	// 加载配置文件
	configFile, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("无法读取配置文件: %v", err)
	}

	// 解析配置文件
	var config Config
	if err := yaml.Unmarshal(configFile, &config); err != nil {
		return nil, fmt.Errorf("无法解析配置文件: %v", err)
	}
	SetupMaxProcs()
	return &config, nil
}

// SendFeishuMsg sends a message to Feishu webhook
func SendFeishuMsg(config *Config, message string) error {
	// Prepare the request payload
	currentTime := GetCurrentTime()
	msg := fmt.Sprintf(ERRORICON+" "+"%s : %s ", currentTime, message)
	payload := fmt.Sprintf(`{
        "msg_type": "text",
        "content": {
            "text": "%s"
        }
    }`, msg)

	// Create a new request
	req, err := http.NewRequest("POST", config.Feishu.WebhookURL, strings.NewReader(payload))
	if err != nil {
		return fmt.Errorf("error creating request: %v", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")

	// Create HTTP client and send request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("error sending request: %v", err)
	}
	defer resp.Body.Close()

	// Check response status
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	return nil
}

// GetCurrentTime returns the current time in a formatted string
func GetCurrentTime() string {
	return time.Now().Format("2006-01-02 15:04:05")
}

func SetupMaxProcs() error {
	_, err := maxprocs.Set(maxprocs.Logger(func(format string, args ...interface{}) {
		fmt.Printf(format, args...)
		fmt.Println("")
	}))
	return err
}

func GetHttpClientWithCondition(config Config) *http.Client {
	client := &http.Client{
		Timeout: time.Duration(config.Settings.CurlTimeout) * time.Second,
		Transport: &http.Transport{
			DialContext: (&net.Dialer{
				Timeout: time.Duration(config.Settings.ConnectTimeout) * time.Second,
			}).DialContext,
		},
	}
	return client
}

func GetMaxProcsNum() int {
	return runtime.GOMAXPROCS(0)
}

func CheckApiHealth(ctx context.Context, client *http.Client, config *Config) {
	maxProcs := GetMaxProcsNum()
	semaphore := make(chan struct{}, maxProcs)
	var wg sync.WaitGroup

	for domain, service := range config.Services {
		for _, endpoint := range service.Endpoints {
			select {
			case <-ctx.Done():
				fmt.Printf("健康检查超时,正在停止\n")
				return
			default:
				wg.Add(1)
				semaphore <- struct{}{}

				go func(domain string, endpoint Endpoint) {
					defer wg.Done()
					defer func() {
						<-semaphore
					}()

					req, url, err := GenerateCheckApiHealthRequest(ctx, domain, endpoint.Path, endpoint.Apikey)
					if err != nil {
						fmt.Printf("generate request failed , err is %s\n", err)
						return
					}
					resp, err := client.Do(req)
					if err != nil {
						if config.Feishu.NotifyOnFailure {
							if err := SendFeishuMsg(config, fmt.Sprintf(ERRORTEXT, url)); err != nil {
								fmt.Printf("❌ 发送飞书通知失败: %v\n", err)
							}
						}
						fmt.Printf("❌ %s 不健康: %v\n", url, err)
						return
					}

					defer resp.Body.Close()

					if resp.StatusCode == http.StatusOK {
						fmt.Printf("✔️ %s 健康 (HTTP %d)\n", url, resp.StatusCode)
					} else {
						if config.Feishu.NotifyOnFailure {
							if err := SendFeishuMsg(config, fmt.Sprintf(ERRORTEXT, url)); err != nil {
								fmt.Printf("❌ 发送飞书通知失败: %v\n", err)
							}
						}
						fmt.Printf("❌ %s 不健康 (HTTP %d)\n", url, resp.StatusCode)
					}
				}(domain, endpoint)
			}
		}
	}
	wg.Wait()
	fmt.Printf("健康检查回合完成。下次检查将在 %d 秒后进行...\n", config.Settings.CheckInterval)
}

func GenerateCheckApiHealthRequest(ctx context.Context, domain string, endpointPath string, endpointApikey string) (req *http.Request, url string, err error) {
	// 构建完整的URL
	url = fmt.Sprintf("https://%s%s", domain, endpointPath)
	fmt.Printf("正在测试 %s...\n", url)

	// 创建带API密钥的请求
	req, err = http.NewRequest("GET", url, nil)
	if err != nil {
		fmt.Printf("❌ 创建请求失败 %s: %v\n", url, err)
		return nil, "", err
	}
	req.Header.Set("apikey", endpointApikey)

	req = req.WithContext(ctx)
	return req, url, nil
}
