#!/usr/bin/env bash
#
# Install / update a curated set of dark colorschemes into Neovim's native
# package directory. `lua/plugins/colors.lua` scans this dir and registers each
# repo as a local plugin, so every theme becomes available to :colorscheme and
# the <leader>uC picker. Light variants are hidden by the picker filter in
# lua/plugins/snacks.lua — this script installs the repos; that filter decides
# what's browsable.
#
# Re-run any time to pull updates, or after editing REPOS below.
# To add a theme: browse https://vimcolorschemes.com, then add either
# "owner/repo" (GitHub) or a full git URL (e.g. GitLab) to REPOS.

set -uo pipefail

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/themes/start"
mkdir -p "$DEST"

REPOS=(
  "folke/tokyonight.nvim"
  "catppuccin/nvim"
  "ellisonleao/gruvbox.nvim"
  "sainnhe/gruvbox-material"
  "rebelot/kanagawa.nvim"
  "rose-pine/neovim"
  "EdenEast/nightfox.nvim"
  "sainnhe/everforest"
  "sainnhe/sonokai"
  "shaunsingh/nord.nvim"
  "navarasu/onedark.nvim"
  "rmehri01/onenord.nvim"
  "nyoom-engineering/oxocarbon.nvim"
  "savq/melange-nvim"
  "Mofiqul/dracula.nvim"
  "scottmckendry/cyberdream.nvim"
  "projekt0n/github-nvim-theme"
  "ribru17/bamboo.nvim"
  "craftzdog/solarized-osaka.nvim"
  "bluz71/vim-moonfly-colors"
  "bluz71/vim-nightfly-colors"
  "tiagovla/tokyodark.nvim"
  "Shatur/neovim-ayu"
  "https://gitlab.com/protesilaos/tempus-themes.git"
)

# Some repos (e.g. tempus-themes) ship their vim colorschemes under vim/ instead
# of colors/, and bundle both light and dark. Expose only the DARK ones as a
# colors/ dir so Neovim can find them and the light ones never appear.
expose_vim_colors() {
  local dir="$1"
  [ -d "$dir/colors" ] && return 0
  ls "$dir"/vim/*.vim >/dev/null 2>&1 || return 0
  mkdir -p "$dir/colors"
  for vf in "$dir"/vim/*.vim; do
    if grep -q 'background=dark' "$vf"; then
      ln -sf "../vim/$(basename "$vf")" "$dir/colors/$(basename "$vf")"
    fi
  done
}

ok=0
fail=0
for repo in "${REPOS[@]}"; do
  case "$repo" in
    *://*) url="$repo"; base="${repo##*/}"; name="${base%.git}" ;;
    *) url="https://github.com/$repo.git"; name="${repo//\//-}" ;;
  esac
  dir="$DEST/$name"
  if [ -d "$dir/.git" ]; then
    printf '↻ %s\n' "$repo"
    git -C "$dir" pull --ff-only --quiet && ok=$((ok + 1)) || { printf '  skip: %s\n' "$repo"; fail=$((fail + 1)); }
  else
    printf '⬇ %s\n' "$repo"
    git clone --depth 1 --quiet "$url" "$dir" && ok=$((ok + 1)) || { printf '  fail: %s\n' "$repo"; fail=$((fail + 1)); }
  fi
  expose_vim_colors "$dir"
done

printf '\nDone: %d ok, %d failed. Location: %s\n' "$ok" "$fail" "$DEST"
printf 'Restart nvim, then browse themes with <leader>uC.\n'
