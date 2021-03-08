FROM ubuntu:20.04
RUN apt-get update && apt-get install -y vim tmux zsh git stow curl
WORKDIR /root/

CMD ["/bin/zsh"]
