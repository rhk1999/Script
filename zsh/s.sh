#!/bin/bash
set -e # 如果命令失败则退出

# 确保目标目录存在
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "${ZSH_CUSTOM_DIR}/plugins"

# 系统更新和基础包安装
sudo apt update && sudo apt upgrade -y
sudo apt install -y zsh git lsd wget # wget 需要显式安装，以防万一

# 安装 Oh My Zsh (非交互式)
# 检查是否已安装，避免重复执行安装程序的核心逻辑
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  # 使用 --unattended 避免交互，它会备份现有的 .zshrc (如果存在) 并创建新的
  sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh already installed."
fi

# 克隆插件 (如果不存在则克隆，如果存在则可以考虑更新)
clone_plugin() {
  local repo_url="$1"
  local plugin_name="$2"
  local target_dir="${ZSH_CUSTOM_DIR}/plugins/${plugin_name}"
  if [ -d "${target_dir}" ]; then
    echo "${plugin_name} already exists. Skipping clone. You might want to update it manually or add 'git pull' logic."
    # (cd "${target_dir}" && git pull) # 可选：如果存在则更新
  else
    echo "Cloning ${plugin_name}..."
    git clone "${repo_url}" "${target_dir}"
  fi
}

clone_plugin https://github.com/TamCore/autoupdate-oh-my-zsh-plugins autoupdate
clone_plugin https://github.com/marlonrichert/zsh-autocomplete zsh-autocomplete
clone_plugin https://github.com/zsh-users/zsh-autosuggestions zsh-autosuggestions
clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git zsh-syntax-highlighting


# 配置 .zshrc
# 完全重写 .zshrc 文件以确保是期望的状态
# 注意：Oh My Zsh 的 --unattended 安装会创建一个 .zshrc。
# 如果你希望保留 Oh My Zsh 安装程序创建的 .zshrc 中的某些内容（如默认主题），
# 则应使用 sed 等工具修改它，而不是完全覆盖。
# 以下代码假定你想要一个完全由脚本控制的 .zshrc。

ZSHRC_FILE="$HOME/.zshrc"

echo "Configuring $ZSHRC_FILE..."

# 创建/覆盖 .zshrc
# 如果 Oh My Zsh 的 unattended install 已经创建了 .zshrc，
# 并且你只想修改 plugins，那么这里的 cat > 会覆盖它。
# 如果你希望保留 OMZ 的 .zshrc 结构，并仅修改 plugins，需要用 sed。
# 例如：sed -i '/^plugins=(/c\plugins=(git autoupdate zsh-autocomplete zsh-autosuggestions zsh-syntax-highlighting)' $ZSHRC_FILE
# 但为了简单和符合原始脚本的“从头开始”的意图（通过rm），这里使用 cat >

cat > "$ZSHRC_FILE" <<EOL
# Path to your oh-my-zsh installation.
export ZSH="\$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo \$RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell" # 或者保留 Oh My Zsh 安装时设置的主题

# Which plugins would you like to load?
# Standard plugins can be found in \$ZSH/plugins/
# Custom plugins may be added to \$ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    autoupdate
    zsh-autocomplete
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source \$ZSH/oh-my-zsh.sh

# User configuration
export UPDATE_ZSH_DAYS=7
export LANG=en_US.UTF-8
# export PATH=\$HOME/bin:/usr/local/bin:\$PATH

# Preferred editor for local and remote sessions
# if [[ -n \$SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For example, you can see examples of this in themes/robbyrussell/robbyrussell.zsh-theme.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
EOL

echo "Zsh configuration complete."
echo "You may need to start a new Zsh session or run 'source ~/.zshrc' for changes to take effect."
echo "If Zsh is not your default shell, you can change it with: chsh -s \$(which zsh)"