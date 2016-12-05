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
            tmux \
            tree \
            unattended-upgrades \
            xclip \
            zip \
            --no-install-recommends

    echo "... DONE... cleaning up\n\n"
    apt-get autoremove
    apt-get autoclean
    apt-get clean

    echo "... setting capslock to control"
    sed -i "s/^XKBOPTIONS=.*/XKBOPTIONS=\"ctrl:nocaps\"/" /etc/default/keyboard

}

no_suspend() {
    # https://wiki.debian.org/SystemdSuspendSedation
    sudo sed -i "s/HandleLidSwitch=.*/HandleLidSwitch=ignore/" /etc/systemd/logind.conf
    sudo sed -i "s/HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/" /etc/systemd/logind.conf
    sudo sed -i "s/IdleActionSec=.*/IdleActionSec=90min/" /etc/systemd/logind.conf

    sudo systemctl restart systemd-logind.service
}


install_i3() {

    echo "update and installing i3wm and some tools..."
    apt-get update
    apt-get install -y \
            alsa-utils \
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
            xorg \
            --no-install-recommends

    echo "... DONE... cleaning up\n\n"
    apt-get autoremove
    apt-get autoclean
    apt-get clean

    no_suspend
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
        aliases=( Masterminds/glide onsi/ginkgo onsi/gomega Compufreak345/alice Compufreak345/manners Compufreak345/go-i18n Compufreak345/excess-router Compufreak345/leaflet-map Compufreak345/jsencrypt gogits/gogs fschl/sql-migrate fschl/CompileDaemon )

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

source get_private_stuff.sh

main() {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
        apt_sources

        base_applications

        install_docker
    fi

    if [[ $cmd == "compose" ]]; then
        install_compose
    elif [[ $cmd == "dotfiles" ]]; then
        get_dotfiles
    elif [[ $cmd == "go" ]]; then
        install_golang
    elif [[ $cmd == "goprojects" ]]; then
        get_public_go_projects
    elif [[ $cmd == "i3" ]]; then
        install_i3
    elif [[ $cmd == "odl" ]]; then
        get_odl_projects
    fi

}

main "$@"
