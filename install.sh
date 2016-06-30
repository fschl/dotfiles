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

deb http://ftp.de.debian.org/debian/ stable-proposed-updates main
deb http://ftp.de.debian.org/debian/ testing main
EOF

}

base_applications() {

    echo "update and installing baseapps..."

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
            ssh \
            sudo \
            tar \
            tree \
            xclip \
            zip \
            --no-install-recommends

    install_i3

    echo "... DONE... cleaning up\n\n"
    apt-get autoremove
    apt-get autoclean
    apt-get clean

}

install_i3() {

    echo "update and installing i3wm..."
    apt-get update
    apt-get install -y \
            feh \
            i3 \
            i3lock \
            i3status \
            rxvt-unicode-256color \
            scrot \
            slim \
            xorg \
            --no-install-recommends

    echo "... DONE... cleaning up\n\n"
    apt-get autoremove
    apt-get autoclean
    apt-get clean
}

install_docker() {

    echo "installing docker from get.docker.com | sh..."
    adduser -aG docker "$USERNAME"

    curl -sSL https://get.docker.com/ | sh

}

install_compose() {

    VERS="1.7.1"
    echo "installing docker-compose $VERS ... curling from github"

    curl -SL https://github.com/docker/compose/releases/download/$VERS/docker-compose-Linux-x86_64 \
         -o /usr/bin/docker-compose
    chmod +x /usr/bin/docker-compose

    echo "... done"

    /usr/bin/docker-compose version
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
    local cmd=$1

    if [[ -z "$cmd" ]]; then
        apt_sources

        base_applications

        install_docker

        install_i3
    fi

    if [[ $cmd == "compose" ]]; then
        install_compose
    elif [[ $cmd == "dotfiles" ]]; then
        get_dotfiles
    fi

}

main "$@"
