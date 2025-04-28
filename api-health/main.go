package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/ekreke/scripts/api-health/utils"
	"github.com/robfig/cron/v3"
)

const (
	ERRORTEXT = "%s is unhealthy"
	ERRORICON = "❌"
)

// 全局配置变量
var config *utils.Config

func main() {
	// 加载配置文件
	var err error
	config, err = utils.InitConfig("config.yaml")
	if err != nil {
		fmt.Printf("❌ %v\n", err)
		return
	}
	// 创建 HTTP 客户端
	client := utils.GetHttpClientWithCondition(*config)

	// 创建定时任务调度器
	c := cron.New(cron.WithSeconds())
	// 注册 API 健康检查任务
	_, err = c.AddFunc(fmt.Sprintf("@every %ds", config.Settings.CheckInterval), func() {
		rctx := context.Background()
		subctx, _ := context.WithTimeout(rctx, time.Duration(config.Settings.ConnectTimeout)*time.Second)
		utils.CheckApiHealth(subctx, client, config)
	})

	if err != nil {
		log.Fatalf("添加 API 健康检查任务失败: %v", err)
	}
	// 注册 SSL 证书检查任务
	_, err = c.AddFunc(config.Settings.InspectionInterval, func() {

		for _, domain := range config.SSL.Domains {

			certInfo, err := utils.CheckSSL(domain.URL, domain.Port, config)
			if err != nil {
				errMsg := fmt.Sprintf("❌ check ssl failed , err is :%v", err)
				fmt.Println(errMsg)
				continue
			}
			info := ""
			if certInfo.DaysRemaining < 10 {
				info = fmt.Sprintf("⚠️ 警告：网站：%s , 证书将在 %.0f 天后过期！", domain.URL, certInfo.DaysRemaining)
				err := utils.SendFeishuMsg(config, info)
				if err != nil {
					fmt.Println(err)
				}
			}
			fmt.Println(info) // 同时在控制台显示
		}
		fmt.Printf("\nSSL 证书巡检完成\n")
	})
	if err != nil {
		log.Fatalf("添加 SSL 证书检查任务失败: %v", err)
	}
	fmt.Printf("服务已启动：\n")
	fmt.Printf("- API 健康检查：每 %d 秒执行一次\n", config.Settings.CheckInterval)
	fmt.Printf("- SSL 证书检查：将在每天 9:20 进行巡检\n")
	// 启动所有定时任务
	c.Start()
	// 保持程序运行
	select {}
}
