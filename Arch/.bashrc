#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
#admin shortcuts
alias root='sudo -i'
alias cls='clear'
alias systemctl='sudo systemctl'
alias turnoff='sudo poweroff'
alias update='sudo pacman -Syu'
alias remove='sudo pacman -Rns'
alias install='sudo pacman -S'
alias install-y='sudo pacman -S --needed --noconfirm'

# pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init - bash)"
fi

# IB_TERMINAL_NEOFETCH_BLOCK
if [[ $- == *i* ]] && command -v neofetch >/dev/null 2>&1; then
    neofetch
fi

# User-local command path
export PATH="$HOME/.local/bin:$PATH"
