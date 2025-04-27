# git scripts
## structure
```bash
 .
├── README.md
├── conf.ini
├── config.sh
└── merge.sh
```

## conf.ini
配置文件

## config.sh
一键更新git配置脚本

## merge.sh
用于自动化合并和同步 git 分支的脚本。

### 功能
- 主要自动化了以下操作:
  - 个人开发分支切换目标开发分支 -> 拉取最新远程代码 -> 切换个人开发分支并合并目标开发分支 -> 推送本地代码到远程

### 使用
当前分支为个人开发分支, 执行以下命令:
```bash
./merge.sh
```
