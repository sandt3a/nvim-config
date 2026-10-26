# Neovim Configuration

C++ competitive programming setup for WSL. Uses Neovim's built-in `vim.pack` to
manage `mini.comment` and `fzf-lua`; plugin versions are pinned in
`nvim-pack-lock.json`.

## Requirements

- **Neovim 0.12+**: needs the built-in `vim.pack` and `sorbet` colorscheme,
  tested with 0.12.6. Check `nvim --version` before installing; if your distro
  package is too old, install a newer build from
  [Neovim Releases](https://github.com/neovim/neovim/releases).
- **git**: download the config and plugins; the first launch needs GitHub access.
- **bash, g++, make, gdb**: build, run, and debug C++; the compiler must support
  C++23.
- **fzf, ripgrep (rg)**: fuzzy finding and full-text search.
- **fd, bat**: recommended for file lookup and syntax-highlighted preview.
- **python3**: required by F4 to run Python files.
- **clip.exe, powershell.exe**: Windows clipboard; requires WSL Windows interop
  and both commands on the WSL `PATH`.

On Arch WSL, install the dependencies with:

```sh
sudo pacman -S --needed neovim git bash gcc make gdb fzf ripgrep fd bat python
```

For other distributions, install the packages listed above and check the
Neovim version. On Ubuntu/Debian, the `fd-find` and `bat` packages may provide
the `fdfind` and `batcat` commands instead.

## Install on Another WSL Machine

If the target location already has a config, back it up and move it away first,
then clone:

```sh
git clone git@github.com:sandt3a/nvim-config.git ~/.config/nvim
cd ~/.config/nvim
cp local.lua.example local.lua
nvim local.lua
```

The SSH URL requires the GitHub SSH key on that machine. HTTPS also works:

```sh
git clone https://github.com/sandt3a/nvim-config.git ~/.config/nvim
```

Set the template directory for this machine in `local.lua`, for example:

```lua
vim.g.cp_template_dir = '~/cp-code/template'
```

Place your own `multicase.cpp` and `singlecase.cpp` in that directory.
`local.lua` is gitignored, and the templates are not stored in this repository.
If `local.lua` does not exist, the default is `~/cp-code/template`.

On first launch, confirm plugin installation when prompted. After the download
finishes, if Neovim reports that plugins are not loaded, run `:restart` (or
quit and reopen). Plugin caches, undo history, and similar state live in
Neovim's data and state directories and do not need to be copied from the old
machine.

## Syncing Two Machines

After changing the config, commit and push from the machine that was modified:

```sh
cd ~/.config/nvim
git status
git add init.lua lua/ README.md .gitignore local.lua.example nvim-pack-lock.json
git commit -m "Update Neovim config"
git push
```

On the other machine, pull when there are no uncommitted changes, then restart
Neovim:

```sh
git -C ~/.config/nvim pull --ff-only
```

Update plugins from inside Neovim with:

```vim
:lua vim.pack.update()
```

Review the updates, confirm when the plugin manager asks, and commit
`nvim-pack-lock.json` as well. After pulling the lockfile on the other machine,
restart; then apply the locked versions and restart again:

```vim
:lua vim.pack.update(nil, { target = 'lockfile' })
```

## Key Bindings

Leader is space.

| Key / command | Action |
| --- | --- |
| `gcc` / `gc` + motion | Comment the current line / selection |
| `<leader>ff` / `<leader>fg` | Find files / search in project |
| `<leader>fb` / `<leader>fo` | Switch buffer / recent files |
| `<leader>fr` / `<leader>fh` | Resume last search / help tags |
| `Ctrl-C` (visual) / `Ctrl-V` (normal or visual) | Copy to / paste from the Windows clipboard |
| F2 / `:CpTemplate singlecase` | Switch / specify the C++ template |
| F3 | Open the same-name `.in` file on the left |
| F4 | Run the current Python file |
| F5 / F8 | Run the existing program / run with the same-name `.in` (C/C++ and Python) |
| F9 / Ctrl-F9 | Build and show errors (C++) / compile the current C/C++ file with `-O2` |
| F10 | Rebuild and start gdb |

Plain `y`, `d`, and `p` use Neovim's internal registers. Building and running
are separate: after editing C++, save and press F9, then press F5 or F8.
