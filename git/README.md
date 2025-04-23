# git scripts
## structure
 .
├── README.md
├── conf.ini
├── config.sh
└── merge.sh

## conf.ini
配置文件

## config.sh
配置自动配置脚本

## merge.sh
用于自动化合并和同步 Git 分支的脚本。

### 功能
- 主要自动化了以下操作:
  - 切换目标开发分支（一般是develop）-> git pull -> 切换个人开发分支并合并目标开发分支 -> push 

### 使用方法
```bash
./merge.sh
```
推荐设置alias
