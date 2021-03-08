# .tmuxist

> Tmux for work

*Disclaimer:* I used this -> [gpakosz/.tmux](https://github.com/gpakosz/.tmux)
config for a while. I manly use tmux for remote server administration so I don't
need fancy stuff like battery charging. If this is what you are looking for give
gpakosz's config a try.

## Features

- Pane sync indicator.
- Hostname / Username indicator.
    - Turns red if User is root.
- Nested remote session awareness.
    - Local keymap can be disabled to issue commands to remote session.
- Vi mode.

In my setting the colors are tweaked to look like
[gruvbox](https://github.com/morhetz/gruvbox).

![Screenshot](shots/tmux.png)

## Usage

To work with colors correctly use `tmux -2`.

## Build and Run

```
docker build -t tmux_test .
docker run -v "${PWD}/:/root" -it tmux_test
```


## Installation

You can simply use the install script to create some symlinks.

```bash
$ cd ~
$ git clone --recursive https://github.com/chrootzius/.tmuxist.git
$ ./.tmuxist/install.sh
```

Or you can use fancy gnu stow (which does pretty much the same)

```bash
$ cd ~
$ git clone --recursive https://github.com/chrootzius/.tmuxist.git
$ cd .tmuxist/
$ stow tmux
```

## Remote session awareness

That means that you can use the same config on your remote system and on your 
local system.

- Same keybindings
- Remote status on top / local status on bottom
- `F12` as toogle key for the local keymap so every keystroke is send to the
  remote session

On the left side of status-right left from the sync indicator is an indicator 
that tells you wether the keymap is turnded on or off.

## Configuration

- For local settings stick to `.tmux.conf.local`
- And for settings in ssh sessions only stick to `.tmux.conf.remote` 

## TODO

- [x] Hostname change per pane.
- [x] Username change per pane.
- [x] URL Grabber / urlview
- [ ] Copy Buffers
- [x] Change color if user is `root`.
