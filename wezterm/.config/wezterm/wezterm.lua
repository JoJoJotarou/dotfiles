-- ~/.wezterm.lua
local wezterm = require 'wezterm'

-- 常用函数
local act = wezterm.action

-- 引入子配置
local key = require 'key'
local ssh = require 'ssh'


local ssh_hosts = wezterm.enumerate_ssh_hosts()

local launch_menu = {}
local ssh_domains = {}

for alias, config in pairs(ssh_hosts) do
    -- 提取关键字段（设置默认值）
    local hostname = config.hostname or alias  -- 如果未指定hostname，使用别名
    local user = config.user or os.getenv('USER')  -- 默认当前用户
    local port = config.port or "22"  -- 默认SSH端口

    -- 构造显示标签和命令
    table.insert(launch_menu, {
        -- label = string.format("%s: %s@%s -p %s", alias, user, hostname, port),
        label = "SSH: " .. alias,
        args = { "ssh", "-p", port, user .. "@" .. hostname },  -- 实际执行的命令
        domain = { DomainName = hostname },
    })

    -- table.insert(ssh_domains, {
    --   name = alias,               -- Host 别名
    --   remote_address = hostname, -- HostName
    --   username = user,       -- User
    -- })

    -- table.insert(launch_menu, {
    --   label = "SSH: " .. alias,
    --   args = { "wezterm", "ssh", alias },
    -- })
end

return {
  --------------------
  -- 基础设置
  --------------------
  font = wezterm.font_with_fallback({
    "Maple Mono NF CN"
  }),
  font_size = 14.0,

  -- 主题
  color_scheme = "Catppuccin Mocha", -- 需要 wezterm 自带的 theme 名称

  -- 背景透明
  window_background_opacity = 0.92,
  text_background_opacity = 1.0,
  macos_window_background_blur = 20, -- macOS 高斯模糊

  -- 光标样式
  default_cursor_style = "BlinkingBlock",

  -- 窗口样式
  window_decorations = "RESIZE", -- 隐藏标题栏，保留窗口缩放
  adjust_window_size_when_changing_font_size = false,

  -- 初始窗口大小
  initial_rows = 40,
  initial_cols = 140,

  -- 滚动缓冲区
  scrollback_lines = 5000,

  -- Tab 样式
  hide_tab_bar_if_only_one_tab = true,
  use_fancy_tab_bar = true,

  --------------------
  -- 快捷键绑定
  --------------------
  -- 取消所有默认的热键
  disable_default_key_bindings = true,
  keys = key.keys,

  launch_menu = launch_menu,
  -- ssh_domains = ssh_domains,

  --------------------
  -- 启动时行为
  --------------------
  default_prog = { "/bin/zsh", "-l" }, -- 你可以换成 fish / bash
}
