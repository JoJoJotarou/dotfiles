local wezterm = require 'wezterm'
local M = {}

-- 自动读取 ~/.ssh/config 主机列表
local ssh_hosts = wezterm.enumerate_ssh_hosts()

-- 构造 ssh_domains 和 launch_menu
M.ssh_domains = {}
M.launch_menu = {}

for _, host in ipairs(ssh_hosts) do
  table.insert(M.ssh_domains, {
    name = host.name,               -- Host 别名
    remote_address = host.remote_address, -- HostName
    username = host.username,       -- User
  })

  table.insert(M.launch_menu, {
    label = "SSH: " .. host.name,
    args = { "wezterm", "ssh", host.name },
  })
end

for alias, config in pairs(ssh_hosts) do
    -- 提取关键字段（设置默认值）
    local hostname = config.hostname or alias  -- 如果未指定hostname，使用别名
    local user = config.user or os.getenv('USER')  -- 默认当前用户
    local port = config.port or "22"  -- 默认SSH端口

    -- 构造显示标签和命令
    table.insert(M.launch_menu, {
        label = string.format("%s: %s@%s -p %s", alias, user, hostname, port),
        args = { "ssh", "-p", port, user .. "@" .. hostname },  -- 实际执行的命令
        domain = { DomainName = hostname },
    })
end

return M
