# Prometheus Docker 监控系统

本目录提供了完整的 Prometheus 监控栈 Docker 部署方案，包含 Prometheus、Node Exporter、cAdvisor、Grafana、AlertManager 等组件。

## 📁 目录结构

```
prometheus/
├── docker-compose.yml              # Docker Compose 配置文件
├── docker-start.sh                 # 启动和管理脚本
├── Dockerfile                      # 自定义 Prometheus 镜像
├── install-prometheus.sh           # 原生安装脚本
├── README.md                      # 本文档
├── config/                        # 配置文件目录
│   ├── prometheus.yml            # Prometheus 主配置
│   ├── alertmanager.yml          # AlertManager 配置
│   └── rules/                    # 告警规则
│       └── node-exporter.yml     # Node Exporter 告警规则
└── grafana/                      # Grafana 配置
    ├── provisioning/
    │   ├── datasources/          # 数据源配置
    │   └── dashboards/           # 仪表板配置
    └── dashboards/               # 仪表板文件
```

## 🚀 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 2GB 可用内存
- 至少 10GB 可用磁盘空间

### 一键启动

```bash
# 克隆或下载本目录后
cd prometheus/

# 启动完整监控栈
./docker-start.sh start
```

### 手动启动

```bash
# 使用 Docker Compose 启动
docker-compose up -d

# 查看服务状态
docker-compose ps
```

## 🌐 访问地址

启动完成后，可以通过以下地址访问各个组件：

| 服务 | 地址 | 用户名 | 密码 | 描述 |
|------|------|--------|------|------|
| Prometheus | http://localhost:9090 | - | - | 主监控系统 |
| Grafana | http://localhost:3000 | admin | admin123 | 可视化仪表板 |
| cAdvisor | http://localhost:8080 | - | - | 容器监控 |
| AlertManager | http://localhost:9093 | - | - | 告警管理 |
| PushGateway | http://localhost:9091 | - | - | 短期任务指标 |
| Node Exporter | http://localhost:9100 | - | - | 系统指标 |

## 📊 组件说明

### Prometheus
- **版本**: v2.54.1
- **端口**: 9090
- **数据保留**: 30天
- **配置**: `config/prometheus.yml`

### Node Exporter
- **版本**: v1.8.2
- **端口**: 9100
- **监控范围**: 系统指标（CPU、内存、磁盘、网络等）

### cAdvisor
- **版本**: v0.49.1
- **端口**: 8080
- **监控范围**: Docker 容器指标

### Grafana
- **版本**: 11.2.2
- **端口**: 3000
- **默认账号**: admin/admin123
- **插件**: grafana-piechart-panel

### AlertManager
- **版本**: v0.27.0
- **端口**: 9093
- **配置**: `config/alertmanager.yml`

## 🔧 管理命令

### 使用管理脚本

```bash
# 启动服务
./docker-start.sh start

# 查看状态
./docker-start.sh status

# 查看日志
./docker-start.sh logs
./docker-start.sh logs prometheus

# 停止服务
./docker-start.sh stop

# 重启服务
./docker-start.sh restart

# 更新镜像
./docker-start.sh update

# 清理所有数据（谨慎使用）
./docker-start.sh clean

# 显示帮助
./docker-start.sh help
```

### 使用 Docker Compose

```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
docker-compose logs -f prometheus

# 启动特定服务
docker-compose up -d prometheus

# 停止所有服务
docker-compose down

# 停止并删除数据卷
docker-compose down -v

# 重新构建并启动
docker-compose up -d --build

# 拉取最新镜像
docker-compose pull

# 扩展服务
docker-compose up -d --scale prometheus=2
```

## 📈 告警配置

### 默认告警规则

系统预置了以下告警规则（位于 `config/rules/node-exporter.yml`）：

- **InstanceDown**: 实例宕机
- **HighCPUUsage**: CPU 使用率过高（>80%）
- **CriticalCPUUsage**: CPU 使用率极高（>95%）
- **HighMemoryUsage**: 内存使用率过高（>85%）
- **CriticalMemoryUsage**: 内存使用率极高（>95%）
- **DiskSpaceLow**: 磁盘空间不足（>85%）
- **DiskSpaceCritical**: 磁盘空间告急（>95%）
- **HighSystemLoad**: 系统负载过高
- **NetworkErrors**: 网络错误
- **DiskIOHigh**: 磁盘 I/O 过高

### 自定义告警规则

1. 在 `config/rules/` 目录下创建新的 `.yml` 文件
2. 编写 PromQL 查询和告警规则
3. 重启 Prometheus 服务

```yaml
# config/rules/custom.yml
groups:
- name: custom-alerts
  rules:
  - alert: CustomAlert
    expr: up{job="custom-job"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Custom service is down"
      description: "Custom service {{ $labels.instance }} has been down for more than 1 minute."
```

### AlertManager 配置

AlertManager 配置文件：`config/alertmanager.yml`

- 支持邮件告警
- 支持 Webhook 告警
- 支持告警分组和抑制

## 📊 Grafana 仪表板

### 预置数据源

- Prometheus: http://prometheus:9090
- 自动配置为默认数据源

### 推荐仪表板

可以从 Grafana 官方市场导入：

1. **Node Exporter Full**: ID 1860
2. **Docker Container Overview**: ID 179
3. **Prometheus 2.0 Overview**: ID 2

### 导入仪表板

```bash
# 方法1：通过 Grafana UI
# 访问 http://localhost:3000
# Dashboard -> Import -> 输入 ID

# 方法2：使用 API
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": {
      "id": null,
      "title": "Node Exporter Full",
      "tags": ["prometheus", "node-exporter"],
      "timezone": "browser",
      "panels": [],
      "time": {"from": "now-1h", "to": "now"},
      "refresh": "5s"
    },
    "overwrite": true,
    "inputs": [{
      "name": "DS_PROMETHEUS",
      "pluginId": "prometheus",
      "type": "datasource",
      "value": "Prometheus"
    }]
  }' \
  http://admin:admin123@localhost:3000/api/dashboards/db
```

## 🔒 安全配置

### 基本认证

```yaml
# config/prometheus.yml
basic_auth_users:
  admin: $2b$12$...
```

### HTTPS 配置

```yaml
# docker-compose.yml
prometheus:
  command:
    - '--web.config.file=/etc/prometheus/web.yml'
  volumes:
    - ./config/web.yml:/etc/prometheus/web.yml
    - ./ssl:/etc/ssl/certs
```

### 防火墙规则

```bash
# 允许监控端口
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9100/tcp  # Node Exporter
sudo ufw allow 8080/tcp  # cAdvisor

# 限制访问（生产环境）
sudo ufw allow from 192.168.1.0/24 to any port 9090
sudo ufw allow from 192.168.1.0/24 to any port 3000
```

## 🗄️ 数据管理

### 数据持久化

使用 Docker 卷持久化数据：

- `prometheus_data`: Prometheus 时序数据
- `grafana_data`: Grafana 配置和仪表板
- `alertmanager_data`: AlertManager 数据

### 数据备份

```bash
# 备份 Prometheus 数据
docker run --rm -v prometheus_prometheus_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/prometheus-data-$(date +%Y%m%d).tar.gz -C /data .

# 备份 Grafana 数据
docker run --rm -v prometheus_grafana_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/grafana-data-$(date +%Y%m%d).tar.gz -C /data .
```

### 数据恢复

```bash
# 恢复 Prometheus 数据
docker run --rm -v prometheus_prometheus_data:/data -v $(pwd):/backup alpine \
  tar xzf /backup/prometheus-data-20241128.tar.gz -C /data

# 重启服务
docker-compose restart prometheus
```

## 🚀 扩展功能

### 添加新监控目标

1. 在 `config/prometheus.yml` 中添加新的 `scrape_configs`
2. 重启 Prometheus 服务

```yaml
scrape_configs:
  - job_name: 'mysql'
    static_configs:
      - targets: ['mysql-exporter:9104']

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx-exporter:9113']
```

### 添加黑盒监控

```yaml
# docker-compose.yml
  blackbox:
    image: prom/blackbox-exporter:v0.25.0
    container_name: blackbox
    ports:
      - "9115:9115"
    volumes:
      - ./config/blackbox.yml:/etc/blackbox_exporter/config.yml
    networks:
      - prometheus_net
    restart: unless-stopped
```

### 添加日志监控（Loki）

```yaml
# docker-compose.yml
  loki:
    image: grafana/loki:3.0.0
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - ./config/loki.yml:/etc/loki/local-config.yaml
      - loki_data:/loki
    networks:
      - prometheus_net
    restart: unless-stopped

  promtail:
    image: grafana/promtail:3.0.0
    container_name: promtail
    volumes:
      - /var/log:/var/log:ro
      - ./config/promtail.yml:/etc/promtail/config.yml
    networks:
      - prometheus_net
    restart: unless-stopped
```

## 🐛 故障排除

### 常见问题

#### 1. 服务无法启动

```bash
# 检查端口占用
netstat -tlnp | grep :9090

# 检查日志
docker-compose logs prometheus

# 检查配置文件语法
docker run --rm -v $(pwd)/config:/etc/prometheus prom/prometheus:latest \
  promtool check config /etc/prometheus/prometheus.yml
```

#### 2. 指标缺失

```bash
# 检查目标状态
curl http://localhost:9090/api/v1/targets

# 检查 scrape 配置
curl http://localhost:9090/api/v1/config
```

#### 3. 告警不工作

```bash
# 检查 AlertManager 配置
curl http://localhost:9093/api/v1/status

# 测试告警规则
curl -X POST http://localhost:9090/api/v1/rules
```

#### 4. Grafana 无法连接 Prometheus

```bash
# 检查网络连接
docker-compose exec grafana ping prometheus

# 检查数据源配置
curl http://admin:admin123@localhost:3000/api/datasources
```

### 性能优化

#### Prometheus 优化

```yaml
# docker-compose.yml
prometheus:
  command:
    - '--storage.tsdb.retention.time=15d'  # 减少保留时间
    - '--storage.tsdb.wal-compression'     # 启用压缩
    - '--query.max-concurrency=20'         # 限制并发查询
    - '--query.timeout=2m'                 # 查询超时
  resources:
    limits:
      memory: 2G
    reservations:
      memory: 1G
```

#### 系统资源监控

```bash
# 监控 Docker 资源使用
docker stats

# 检查磁盘空间
df -h

# 监控内存使用
free -h
```

## 📚 相关资源

- [Prometheus 官方文档](https://prometheus.io/docs/)
- [Grafana 官方文档](https://grafana.com/docs/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [Node Exporter 文档](https://github.com/prometheus/node_exporter)
- [Prometheus 最佳实践](https://prometheus.io/docs/practices/)

## 📞 支持

如果遇到问题：

1. 查看本文档的故障排除部分
2. 检查容器日志：`./docker-start.sh logs`
3. 验证配置文件语法
4. 提交 Issue 或联系维护团队

---

**版本信息**:
- Prometheus: v2.54.1
- Grafana: v11.2.2
- Node Exporter: v1.8.2
- cAdvisor: v0.49.1
- AlertManager: v0.27.0

**最后更新**: 2025-11-28