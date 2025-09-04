# 为当前目录（递归）下所有 .sh 文件添加执行权限
find . -type f -name "*.sh" -exec chmod +x {} \;
