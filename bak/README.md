# MySQL数据库脚本备份说明
## 脚本配置
配置脚本中的数据库连接信息以及需要备份的schema名称
```shell
# Database configuration
DB_HOST=""
DB_PORT=""
DB_USER="root"
DB_PASSWORD=""
BASE_BACKUP_DIR=""
# List of schemas to backup
SCHEMA_NAMES=(
)
```

## crontab配置
```shell
# 查看crontab任务
sudo crontab -l
# 编辑crontab任务
sudo crontab -e
```

以下路径需要手动修改为真实脚本路径以及日志存放路径
```shell 
0 * * * * /data/db-bak/backup_db.sh >> /data/db-bak/backup_db.log 2>&1
```

## 手动通过dump数据恢复
```shell
mysql -h xxx -P xxx -u xxx -p'xxx' xxx < xxx.sql
```