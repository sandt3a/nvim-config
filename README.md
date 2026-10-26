# Neovim 配置

用于 WSL 的 C++ 算法竞赛配置。使用 Neovim 内置 `vim.pack` 管理
`mini.comment` 和 `fzf-lua`，插件版本记录在 `nvim-pack-lock.json` 中。

## 环境依赖

- **Neovim 0.12+**：需要内置 `vim.pack` 和 `sorbet` 配色，当前使用 0.12.5。
  安装前检查 `nvim --version`；发行版仓库版本过旧时可从
  [Neovim Releases](https://github.com/neovim/neovim/releases) 安装新版。
- **git**：下载配置和插件；首次启动需要访问 GitHub。
- **bash、g++、make、gdb**：编译、运行和调试 C++，编译器需支持 C++23。
- **fzf、ripgrep（rg）**：模糊查找与全文搜索。
- **fd、bat**：建议安装，用于文件查找和带语法高亮的预览。
- **python3**：使用 F4 运行 Python 文件时需要。
- **clip.exe、powershell.exe**：Windows 剪贴板，需要启用 WSL 的 Windows
  互操作，并让这两个命令可从 WSL 的 PATH 找到。

Arch WSL 可安装以下软件包：

```sh
sudo pacman -S --needed neovim git bash gcc make gdb fzf ripgrep fd bat python
```

其他发行版按上面的依赖列表安装，并确认 Neovim 版本。Ubuntu/Debian 的
`fd-find`、`bat` 软件包可能提供名为 `fdfind`、`batcat` 的命令。

## 在另一台 WSL 上安装

如果目标位置已有配置，先自行备份并移走，再克隆：

```sh
git clone git@github.com:sandt3a/nvim-config.git ~/.config/nvim
cd ~/.config/nvim
cp local.lua.example local.lua
nvim local.lua
```

使用 SSH 地址需要目标电脑的 SSH 密钥已关联 GitHub。也可使用 HTTPS：

```sh
git clone https://github.com/sandt3a/nvim-config.git ~/.config/nvim
```

在 `local.lua` 中填写这台电脑的模板目录，例如：

```lua
vim.g.cp_template_dir = '~/cp-code/template'
```

将自己的 `multicase.cpp` 和 `singlecase.cpp` 手动放到该目录。
`local.lua` 已被 Git 忽略，模板文件也不存放在本仓库。
不创建 `local.lua` 时默认使用 `~/cp-code/template`。

首次启动 Neovim 时，按提示确认安装插件。下载结束后，如果提示插件尚未加载，
执行 `:restart`（或退出后重新打开）。插件缓存、撤销历史等由 Neovim 存放在
数据和状态目录，不需要从旧电脑复制。

## 两台电脑同步

修改配置后，在修改所在的电脑提交并推送：

```sh
cd ~/.config/nvim
git status
git add init.lua lua/ README.md .gitignore local.lua.example nvim-pack-lock.json
git commit -m "Update Neovim config"
git push
```

另一台电脑没有未提交改动时拉取，然后重启 Neovim：

```sh
git -C ~/.config/nvim pull --ff-only
```

插件更新可在 Neovim 中执行：

```vim
:lua vim.pack.update()
```

查看更新内容并按插件管理器提示确认后，将 `nvim-pack-lock.json` 一起提交。
另一台电脑拉取锁定文件后，先重启；对已安装插件执行以下命令并确认，
使其使用锁定文件中的版本，然后再次重启：

```vim
:lua vim.pack.update(nil, { target = 'lockfile' })
```

## 常用操作

Leader 是空格。

| 按键 / 命令 | 功能 |
| --- | --- |
| `gcc` / `gc` + motion | 注释当前行 / 选区 |
| `<leader>ff` / `<leader>fg` | 找文件 / 全文搜索 |
| `<leader>fb` / `<leader>fo` | 切换 buffer / 最近文件 |
| `<leader>fr` / `<leader>fh` | 恢复搜索 / 搜索帮助 |
| `Ctrl-C`（可视模式） / `Ctrl-V`（普通或可视模式） | 复制到 / 粘贴自 Windows 剪贴板 |
| F2 / `:CpTemplate singlecase` | 切换 / 指定 C++ 模板 |
| F3 | 在左侧打开同名 `.in` 文件 |
| F4 | 运行当前 Python 文件 |
| F5 / F8 | 运行已有程序 / 从同名 `.in` 读取输入（C/C++ 和 Python） |
| F9 / Ctrl-F9 | 编译并显示错误（C++） / 使用 `-O2` 编译当前 C/C++ 文件 |
| F10 | 重新编译并启动 gdb |

普通 `y`、`d`、`p` 使用 Neovim 内部寄存器。程序的编译和运行是分开的：
修改 C++ 后先保存并按 F9，再按 F5 或 F8 运行。
