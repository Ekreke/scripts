# Grafana 服务

这个文件夹包含了使用 Docker 运行 Grafana 服务所需的一切。

## 文件概览

- `Dockerfile` - 自定义 Grafana 镜像配置
- `start-grafana.sh` - 构建和启动 Grafana 服务的脚本
- `stop-grafana.sh` - 停止和移除 Grafana 服务的脚本
- `docker-compose.yml` - 用于更简单部署的 Docker Compose 配置
- `grafana.ini` - 基础 Grafana 配置文件

## 快速开始

### 方法1：使用启动脚本（推荐）

```bash
cd grafana
./start-grafana.sh
```

### 方法2：使用 Docker Compose

```bash
cd grafana
docker-compose up -d
```

### 方法3：直接使用 Docker

```bash
cd grafana
docker build -t grafana-custom .
docker run -d \
  --name grafana-service \
  -p 3000:3000 \
  -v $(pwd)/grafana-data:/var/lib/grafana \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=admin123 \
  grafana-custom
```

## 访问 Grafana

服务启动后，您可以通过以下方式访问 Grafana：
- **URL**: http://localhost:3000
- **用户名**: admin
- **密码**: admin123

## 停止服务

### 使用停止脚本
```bash
cd grafana
./stop-grafana.sh
```

### 使用 Docker Compose
```bash
cd grafana
docker-compose down
```

### 直接使用 Docker
```bash
docker stop grafana-service
docker rm grafana-service
```

## 持久化数据

Grafana 数据持久化在以下位置：
- **数据**: `./grafana-data/data` - 数据库和仪表板数据
- **日志**: `./grafana-data/logs` - 应用程序日志
- **配置**: `./grafana-data/provisioning` - 配置文件

## 配置

您可以修改以下内容：
- **管理员凭据**: 编辑启动脚本或 docker-compose.yml 中的环境变量
- **端口**: 将端口映射从 3000:3000 更改为您需要的端口
- **配置**: 修改 `grafana.ini` 进行高级设置

## 常用命令

```bash
# 查看容器日志
docker logs grafana-service

# 实时跟踪容器日志
docker logs -f grafana-service

# 检查容器状态
docker ps

# 进入容器 shell
docker exec -it grafana-service /bin/bash
```

## 故障排除

1. **端口已被占用**: 在启动脚本或 docker-compose.yml 中更改端口映射
2. **权限问题**: 确保 Docker 正在运行且您有使用 Docker 的权限
3. **容器无法启动**: 使用 `docker logs grafana-service` 检查日志

## 自定义

### 添加插件
编辑 Dockerfile 并将插件添加到 `GF_INSTALL_PLUGINS` 环境变量：

```dockerfile
ENV GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
```

### 自定义配置
1. 修改 `grafana.ini` 进行高级设置
2. 将自定义配置文件挂载到 `/etc/grafana/`
3. 使用环境变量进行运行时配置

## 数据备份

备份您的 Grafana 数据：

```bash
# 首先停止服务
./stop-grafana.sh

# 备份数据目录
tar -czf grafana-backup-$(date +%Y%m%d).tar.gz grafana-data/

# 重启服务
./start-grafana.sh
```

## 注意事项

- 首次启动时会自动创建管理员用户
- 所有数据和配置都会持久化到本地 `grafana-data` 目录
- 建议在生产环境中更改默认的管理员密码
- 可以通过修改配置文件来自定义 Grafana 的行为