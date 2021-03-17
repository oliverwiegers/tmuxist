#!/usr/bin/env sh

if [ "$(command -v stow)" ]; then
    stow tmux
else
    ln -s "$HOME/.tmuxist/tmux/.tmux.conf" "$HOME/"
    ln -s "$HOME/.tmuxist/tmux/.tmux.conf.local" "$HOME/"
    ln -s "$HOME/.tmuxist/tmux/.tmux.conf.remote" "$HOME/"
fi
