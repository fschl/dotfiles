#!/bin/bash
set -e

# install.sh
#	This script installs my basic setup for a debian laptop

USERNAME=fschl

apt_sources() {
    cat <<-EOF > /etc/apt/sources.list
deb http://ftp.de.debian.org/debian/ stable main contrib non-free
deb-src http://ftp.de.debian.org/debian/ stable main contrib non-free

deb http://security.debian.org/ stable/updates main contrib non-free
deb-src http://security.debian.org/ stable/updates main contrib non-free

# stable-updates, previously known as 'volatile'
deb http://ftp.de.debian.org/debian/ stable-updates main contrib non-free
deb-src http://ftp.de.debian.org/debian/ stable-updates main contrib non-free

deb http://ftp.fr.debian.org/debian/ stable-proposed-updates main
deb http://ftp.fr.debian.org/debian/ testing main
EOF

}

base_applications() {
    apt-get update
    apt-get upgrade

    apt-get install -y \
            alsa-utils \
            apt-transport-https \
            automake \
            bash-completion \
            bzip2 \
            ca-certificates \
            cmake \
            coreutils \
            curl \
            gcc \
            git \
            gnupg \
            gnupg-agent \
            gnupg-curl \
            grep \
            htop \
            locales \
            make \
            mount \
            net-tools \
            pulseaudio \
            rxvt-unicode-256color \
            ssh \
            sudo \
            tar \
            tree \
            xclip \
            zip \
            --no-install-recommends

    install_i3

    apt-get autoremove
    apt-get autoclean
    apt-get clean

}

install_i3() {
    apt-get update
    apt-get install -y \
            feh \
            i3 \
            i3lock \
            i3status \
            scrot \
            slim \
            xorg \
            --no-install-recommends
}

install_docker() {
    adduser -aG docker "$USERNAME"

    curl -sSL https://get.docker.com/ | sh

    curl -SL https://github.com/docker/compose/releases/download/1.5.2/docker-compose-Linux-x86_64 \
         -o /usr/bin/docker-compose
    chmod +x /usr/bin/docker-compose
}

get_dotfiles() {

    (
        git clone https://github.com/fschl/dotfiles.git "/home/$USERNAME/dotfiles"
        cd "/home/$USERNAME/dotfiles" && make

        git clone https://github.com/fschl/dockerfiles.git "/home/$USERNAME/dockerfiles"

        git clone https://github.com/fschl/.emacs.d.git "/home/$USERNAME/.emacs.d"
    )
}

main() {
    apt_sources

    base_applications

    install_docker

    install_i3
}

main "$@"
