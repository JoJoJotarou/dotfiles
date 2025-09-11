local wezterm = require 'wezterm'

-- 常用函数
local act = wezterm.action

local M = {}

M.keys = {
    --------------------
    -- 字体缩放
    --------------------
    { key = "=", mods = "CTRL", action = act.IncreaseFontSize }, -- 放大字体
    { key = "-", mods = "CTRL", action = act.DecreaseFontSize }, -- 缩小字体
    { key = "0", mods = "CTRL", action = act.ResetFontSize },    -- 恢复默认字体大小

    -- 标签管理
    { key = "t", mods = "CMD", action = act.SpawnTab "CurrentPaneDomain" },
    { key = "w", mods = "CMD", action = act.CloseCurrentTab { confirm = true } },
    { key = "{", mods = "CMD", action = act.ActivateTabRelative(1) },
    { key = "}", mods = "CMD", action = act.ActivateTabRelative(-1) },

    -- 调整面板大小
    { key = "LeftArrow", mods = "CMD", action = act.AdjustPaneSize { "Left", 3 } },
    { key = "RightArrow", mods = "CMD", action = act.AdjustPaneSize { "Right", 3 } },
    { key = "UpArrow", mods = "CMD", action = act.AdjustPaneSize { "Up", 3 } },
    { key = "DownArrow", mods = "CMD", action = act.AdjustPaneSize { "Down", 3 } },

    -- 面板左右、上下拆分和关闭
    { key = "\\", mods = "CMD", action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
    { key = "-", mods = "CMD", action = act.SplitVertical { domain = "CurrentPaneDomain" } },
    { key = "w", mods = "CMD", action = act.CloseCurrentPane { confirm = true } },  -- 放在 CloseCurrentTab 后面可以相通的快捷键关闭tab和pane

    -- 复制粘贴
    { key = "c", mods = "CMD", action = act.CopyTo "Clipboard" },
    { key = "v", mods = "CMD", action = act.PasteFrom "Clipboard" },

    -- activate pane selection mode with numeric labels
    {
        key = '9',
        mods = 'CMD',
        action = act.PaneSelect {
            alphabet = '1234567890',
            mode="Activate",
        },
    },
    -- show the pane selection mode, but have it swap the active and selected panes
    {
        key = '0',
        mods = 'CMD',
        action = act.PaneSelect {
            alphabet = '1234567890',
            mode = 'SwapWithActive',
        },
    },
    -- 打开 Launch Menu，只显示 SSH 主机
    {
        key = "P",
        mods = "CTRL|SHIFT",
        action = act.ShowLauncherArgs { flags = 'FUZZY|DOMAINS' },
    },
    { key = 'l', mods = 'ALT', action = act.ShowLauncher }
}

return M