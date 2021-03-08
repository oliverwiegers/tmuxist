#!/usr/bin/env sh

if [ "$(command -v stow)" ]; then
    stow tmux
else
    ln -s "$HOME/personal_tmux/tmux/.tmux.conf" "$HOME/"
    ln -s "$HOME/personal_tmux/tmux/.tmux.conf.local" "$HOME/"
    ln -s "$HOME/personal_tmux/tmux/.tmux.conf.remote" "$HOME/"
fi
