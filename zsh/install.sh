#!/bin/bash

sudo apt update && sudo apt upgrade -y

sudo apt install -y zsh git lsd

sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $ZSH_CUSTOM/plugins/autoupdate

git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

rm -rf .zshrc
touch .zsh

echo 'export ZSH="$HOME/.oh-my-zsh"' >> ~/.zshrc

echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc

echo 'export UPDATE_ZSH_DAYS=7' >> ~/.zshrc

echo 'export LANG=en_US.UTF-8' >> ~/.zshrc

echo 'plugins=(git autoupdate zsh-autocomplete zsh-autosuggestions zsh-syntax-highlighting)' >> ~/.zshrc



