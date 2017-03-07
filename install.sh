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

    apt update
    apt upgrade

    DEBIAN_FRONTEND=noninteractive

    apt install -y \
        apt-transport-https \
        automake \
        bash-completion \
        bmon \
        bzip2 \
        ca-certificates \
        cmake \
        coreutils \
        curl \
        dnsutils \
        gcc \
        git \
        gnupg \
        gnupg2 \
        gnupg-agent \
        gnupg-curl \
        grep \
        htop \
        iotop \
        locales \
        make \
        mount \
        net-tools \
        rsync \
        ssh \
        sudo \
        tar \
        tinc \
        tmux \
        tree \
        vim \
        zip \
        --no-install-recommends

    echo "... DONE... cleaning up\n\n"
    apt autoremove
    apt autoclean
    apt clean

}

install_server_base() {

    echo "update and installing server base tools..."

    DEBIAN_FRONTEND=noninteractive

    apt update
    apt install -y \
        fail2ban \
        logwatch \
        unattended-upgrades \
        --no-install-recommends

    echo "... DONE... cleaning up\n\n"
    apt autoremove
    apt autoclean
    apt clean

    echo "setting up logwatch..."
    cat <<-EOF > /etc/cron.daily/00logwatch
/usr/sbin/logwatch --output mail --mailto you@example.com --detail high

EOF
    echo " ... DONE"

    # TODO: is this really needed?
    echo "set unattended upgrades..."
    cat <<-EOF > /etc/apt/apt.conf.d/10periodic
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";

EOF
    echo " ... DONE"

}


no_suspend() {
    # https://wiki.debian.org/SystemdSuspendSedation
    sudo sed -i "s/HandleLidSwitch=.*/HandleLidSwitch=ignore/" /etc/systemd/logind.conf
    sudo sed -i "s/HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/" /etc/systemd/logind.conf
    sudo sed -i "s/IdleActionSec=.*/IdleActionSec=90min/" /etc/systemd/logind.conf

    # turn off screen blanking
    # https://www.raspberrypi.org/forums/viewtopic.php?f=66&t=18200&sid=135af53eb82496bc64f4c0eefbc86d2c&start=25
    # http://raspberrypi.stackexchange.com/questions/752/how-do-i-prevent-the-screen-from-going-blank
    xset s noblank

    sudo systemctl restart systemd-logind.service
}

install_i3() {

    echo "update and installing i3wm and some tools..."

    DEBIAN_FRONTEND=noninteractive

    apt update
    apt install -y \
        alsa-utils \
        clipit \
        emacs25 \
        feh \
        fswebcam \
        i3 \
        i3lock \
        i3status \
        keepass2 \
        pulseaudio \
        rxvt-unicode-256color \
        scrot \
        shotwell \
        slim \
        xclip \
        xorg \
        --no-install-recommends

    echo "... DONE... cleaning up\n\n"
    apt autoremove
    apt autoclean
    apt clean

    no_suspend

    echo "... setting capslock to control"
    sed -i "s/^XKBOPTIONS=.*/XKBOPTIONS=\"ctrl:nocaps\"/" /etc/default/keyboard

}

install_docker() {

    # https://docs.docker.com/engine/installation/binaries/#install-static-binaries
    VERS="17.03.0-ce"
    echo "installing docker binary Version $VERS ..."
    # https://github.com/tianon/cgroupfs-mount/blob/master/cgroupfs-mount

    curl -SL https://get.docker.com/builds/Linux/x86_64/docker-$VERS.tgz \
         -o /tmp/docker.tgz
    curl -SL https://get.docker.com/builds/Linux/x86_64/docker-$VERS.tgz.sha256 \
         -o /tmp/docker.tgz.sha256

    if [ ! $(cat /tmp/docker.tgz.sha256 | sha256sum -c -) ]; then
        echo "... checksum failed... stopping"
        exit 1;
    fi

    tar -xvzf docker.tgz
    mv docker/* /usr/bin
    rm /tmp/docker.tgz
    rm /tmp/docker.tgz.sha256

    sudo groupadd docker
    sudo adduser -aG docker "$USERNAME"

    #     curl -sSL https://get.docker.com/ | sh

    #     sudo apt-get update
    #     sudo apt-get install apt-transport-https ca-certificates gnupg2
    #     sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

    #     cat <<-EOF > /etc/apt/sources.list.d/docker.list
    # deb https://apt.dockerproject.org/repo $REPO main
    # EOF

    #     apt-get update
    #     apt-cache policy docker-engine
    #     apt-get update && apt-get install docker-engine
}

install_compose() {

    VERS="1.11.2"
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

# install/update golang from source
install_golang() {
    export GO_VERSION=1.6.2
    export GO_SRC=/usr/local/go

    # if we are passing the version
    if [[ ! -z "$1" ]]; then
        export GO_VERSION=$1
    fi

    # subshell because we `cd`
    (
        curl -sSL "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz" | sudo tar -v -C /usr/local -xz
    )

    # get commandline tools
    (
        set -x
        set +e
        go get github.com/golang/lint/golint
        go get golang.org/x/tools/cmd/cover
        go get golang.org/x/review/git-codereview
        go get golang.org/x/tools/cmd/goimports
        go get golang.org/x/tools/cmd/gorename

        go get github.com/FiloSottile/vendorcheck
        go get github.com/nsf/gocode
        #done
    )
}

get_public_go_projects() {

    (
        aliases=( Masterminds/glide onsi/ginkgo onsi/gomega gogits/gogs fschl/CompileDaemon )

        for project in "${aliases[@]}"; do
            owner=$(dirname "$project")
            repo=$(basename "$project")
            if [[ -d "${HOME}/${repo}" ]]; then
                rm -rf "${HOME}/${repo}"
            fi

            mkdir -p "${GOPATH}/src/github.com/${owner}"

            if [[ ! -d "${GOPATH}/src/github.com/${project}" ]]; then
                (
                    # clone the repo
                    cd "${GOPATH}/src/github.com/${owner}"
                    git clone "https://github.com/${project}.git"
                    # fix the remote path, since our gitconfig will make it git@
                    cd "${GOPATH}/src/github.com/${project}"
                    git remote set-url origin "https://github.com/${project}.git"
                )
            else
                echo "found ${project} already in gopath"
            fi

            # make sure we create the right git remotes
            # if [[ "$owner" != "fschl" ]]; then
            #   (
            #   cd "${GOPATH}/src/github.com/${project}"
            #   git remote set-url --push origin no_push
            #   git remote add jfrazelle "https://github.com/fschl/${repo}.git"
            #   )
            # fi

            # create the alias
            # ln -snvf "${GOPATH}/src/github.com/${project}" "${HOME}/${repo}"
        done

        # create symlinks from personal projects to
        # the ${HOME} directory
        projectsdir=$GOPATH/src/github.com/fschl
        base=$(basename "$projectsdir")
        find "$projectsdir" -maxdepth 1 -not -name "$base" -type d -print0 | while read -d '' -r dir; do
            base=$(basename "$dir")
            ln -snvf "$dir" "${HOME}/${base}"

        done
    )
}

if [ -f "./get_private_stuff.sh" ]; then
    source get_private_stuff.sh
fi

main() {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
        echo "Usage: \n base | desktop | server | dotfiles | compose | go"
    fi

    if [[ $cmd == "compose" ]]; then
        install_compose
    elif [[ $cmd == "base" ]]; then
        apt_sources

        base_applications

        install_docker

        install_compose
    elif [[ $cmd == "docker" ]]; then
        install_docker
    elif [[ $cmd == "dotfiles" ]]; then
        get_dotfiles
    elif [[ $cmd == "go" ]]; then
        install_golang
    elif [[ $cmd == "goprojects" ]]; then
        get_public_go_projects
    elif [[ $cmd == "server" ]]; then
        install_server_base
    elif [[ $cmd == "desktop" ]]; then
        install_i3
    fi

}

main "$@"
