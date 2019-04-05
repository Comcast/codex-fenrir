#!/usr/bin/env bash

docker --version
docker-compose --version

function check() {
  if [[ $1 -ne 0 ]] ; then
      exit 1
  fi
}

function fenrir-docker {
    FENRIR_VERSION="$(make version -s)"
    make docker
    check $?
}

function svalinn-docker {
    echo "Building Svalinn Image"
    git clone https://github.com/Comcast/codex-svalinn.git 2> /dev/null || true
    cd codex-svalinn
    SVALINN_VERSION="$(make version -s)"
    make docker
    check $?
    cd ..
    printf "\n"
}

function gungnir-docker {
    echo "Building Gungnir Image"
    git clone https://github.com/Comcast/codex-gungnir.git 2> /dev/null || true
    cd codex-gungnir
    GUNGNIR_VERSION="$(make version -s)"
    make docker
    check $?
    cd ..
    printf "\n"
}

function deploy {
    echo "Deploying Cluster"
    docker swarm init
    git clone https://github.com/Comcast/codex.git 2> /dev/null || true
    pushd codex/deploy/docker-compose
    SVALINN_VERSION=$SVALINN_VERSION GUNGNIR_VERSION=$GUNGNIR_VERSION FENRIR_VERSION=$FENRIR_VERSION docker stack deploy codex --compose-file docker-compose.yml
    check $?
    popd
    printf "\n"
}

fenrir-docker
cd ..

svalinn-docker
gungnir-docker
echo "Gungnir V:$GUNGNIR_VERSION Svalinn V:$SVALINN_VERSION Fenrir V:$FENRIR_VERSION"
deploy
go get -d github.com/Comcast/codex/tests/...
printf "Starting Tests \n\n\n"
go run github.com/Comcast/codex/tests/runners/travis -feature=codex/tests/features
check $?
