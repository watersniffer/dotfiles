# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# AMOLED: black surfaces, one light accent. Fixed, no pywal.
AGNOSTER_DIR_FG="#d7d6df"
AGNOSTER_DIR_BG="#61afef"
AGNOSTER_GIT_CLEAN_BG="#98c379"
AGNOSTER_GIT_CLEAN_FG="#98c379"
AGNOSTER_GIT_DIRTY_BG="#e06c75"
AGNOSTER_GIT_DIRTY_FG="#e5c07b"

# Arrow, path, git.
setopt PROMPT_SUBST

_prompt_dir() {
    print -n "%F{$AGNOSTER_DIR_BG}%(1~|%3~|%~)%f"
}

_prompt_git() {
    if git rev-parse --git-dir >/dev/null 2>&1; then
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            print -n " %F{$AGNOSTER_GIT_DIRTY_BG}git%f%F{$AGNOSTER_GIT_DIRTY_FG} %3~%f"
        else
            print -n " %F{$AGNOSTER_GIT_CLEAN_BG}git%f%F{$AGNOSTER_GIT_CLEAN_FG} %3~%f"
        fi
    fi
}

PROMPT='%F{$AGNOSTER_DIR_FG}→%f $(_prompt_dir)$(_prompt_git) '

export MANPATH="/usr/local/man:$MANPATH"

# Skip pacman's "Proceed with installation? [Y/n]". Runs nothing without the
# alias in scripts, since aliases are interactive-shell only.
alias yay='yay --noconfirm'