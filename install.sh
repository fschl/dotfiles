#!/bin/bash
set -e

# install.sh
#	This script installs my basic setup for a debian laptop

USERNAME=fschl

apt_sources() {
    cat <<-EOF > /etc/apt/sources.list
deb http://ftp.de.debian.org/debian/ jessie main contrib non-free
deb-src http://ftp.de.debian.org/debian/ jessie main contrib non-free

deb http://security.debian.org/ jessie/updates main contrib non-free
deb-src http://security.debian.org/ jessie/updates main contrib non-free

# jessie-updates, previously known as 'volatile'
deb http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free
deb-src http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free
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
            locales \
            make \
            mount \
            net-tools \
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
            --install-no-recommends
    
}

get_dotfiles() {

    (
        cd "/home$USERNAME"

        git clone https://github.com/fschl/dotfiles.git "/home/$USERNAME/dotfiles"
        cd "/home/$USERNAME/dotfiles"

        make

        cd "/home/$USERNAME"
        git clone https://github.com/fschl/dockerfiles.git "/home/$USERNAME/dockerfiles"

        git clone https://github.com/fschl/.emacs.d.git "/home/$USERNAME/.emacs.d"        
    )
}

main() {
    apt_sources

    base_applications

    install_i3
}

main "$@"
