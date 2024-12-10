#! /bin/bash

cd "$(dirname "$0")"

container_name=

function cleanup()
{
  [ ! -z "${container_name}" ] && docker rm "${container_name}"
  exit -1
}

function build_image()
{
    NAME="$1"
    UBUNTU_VER="$2"
    CLANG_VER="$3"
    VERSION="ubuntu${UBUNTU_VER}_clang${CLANG_VER}"
    docker image rm nemirtingas/${NAME}:${VERSION} --force
    docker image rm ${NAME}:${VERSION} --force
    container_name="$(mktemp -u XXXXXXXXXXXX)"
    echo "Container: ${container_name}"
    docker build --build-arg CLANG_VER=${CLANG_VER} --build-arg "UBUNTU_VER=${UBUNTU_VER}" --no-cache --rm -t ${NAME}:${VERSION} . &&
    docker run "--name=${container_name}" ${NAME}:${VERSION} /bin/bash -c exit &&
    docker commit -m "${NAME} image built on ubuntu${UBUNTU_VER} with ${VERSION} and clang ${CLANG_VER}" -a "Nemirtingas" "${container_name}" nemirtingas/${NAME}:${VERSION} &&
    docker push nemirtingas/${NAME}:${VERSION} &&
    docker rm "${container_name}"

    cleanup
}

trap cleanup INT
build_image "nemirtingas_compilation_base" "22.04" "17"
