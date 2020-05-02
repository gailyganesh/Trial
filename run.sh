#!/bin/bash -e
# build script for the project
ROOT_DIR=$PWD
TOOLS_DIR=$ROOT_DIR/tools
CMAKE=$TOOLS_DIR/cmake/bin/cmake
BUILD_DIR=$ROOT_DIR/build
RELEASE_BUILD_DIR=$BUILD_DIR/release
DEBUG_BUILD_DIR=$BUILD_DIR/debug
INSTALL_DIR=$ROOT_DIR/bin 
BUILD_TYPE=All

while getopts ":hb:" opt; do
    case $opt in
        h)
            usage >&2
            exit 0
            ;;
        b)
            BUILD_TYPE=$OPTARG;;
        \?)
            echo "invalid option: $OPTARG" 1>&2
            usage >&2
            exit 1
            ;;
        :)
            echo "invalid option: $OPTARG requires an argument" >&2
            usage >&2
            exit 1
            ;;
    esac
done

shift $((OPTIND -1))

if [ "$BUILD_TYPE" != "All" ];
then
    echo "invalid build type: $BUILD_TYPE" 1>&2
    usage >&2
    exit 1
fi

function usage () {
    echo "usage: $0 [-h] <command>"
    echo "       -h      Print this help and exit."
    echo "       -b      Support build types are Release and Debug"
    echo "        command:"
    echo "                 generate"
    echo "                 build"
    echo "                 clean"
}

[ $# -ge 1 ] || { usage >&2; exit 1; }

# Configure compiler path 
CXX_COMPILER_PATH=/usr/bin/g++-5
C_COMPILER_PATH=/usr/bin/gcc-5

# Configure global camke flag
CMAKE_PARALLEL=${CMAKE_PARALLEL:-4}
GLOBAL_CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_CXX_COMPILER:PATH=${CXX_COMPILER_PATH}"
GLOBAL_CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_C_COMPILER:PATH=${C_COMPILER_PATH}"

function generate()
{
    if [ "$BUILD_TYPE" = "Release" ];
    then
        generate_release
    elif [ "$BUILD_TYPE" = "Debug" ]
    then
        generate_debug
    else
        generate_release
        generate_debug
    fi
}

function generate_release()
{
    echo "generate the project in Release"

    local cmake_flags=""
    cmake_flags="${GLOBAL_CMAKE_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_DIR}/release"
    cmake_flags="${cmake_flags} -DCMAKE_BUILD_TYPE=Release"
    cmake_flags="${cmake_flags} ${CMAKE_ADDITIONAL_FLAGS}"
    cmake_flags="${cmake_flags} -S ${ROOT_DIR}"
    cmake_flags="${cmake_flags} -B ${RELEASE_BUILD_DIR}"

    ${CMAKE} ${cmake_flags}
}

function generate_debug()
{
    echo "generate the project in Debug: ${DEBUG_BUILD_DIR}"

    local cmake_flags=""
    cmake_flags="${GLOBAL_CMAKE_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_DIR}/debug"
    cmake_flags="${cmake_flags} -DCMAKE_BUILD_TYPE=Debug"
    cmake_flags="${cmake_flags} ${CMAKE_ADDITIONAL_FLAGS}"
    cmake_flags="${cmake_flags} -S ${ROOT_DIR}"
    cmake_flags="${cmake_flags} -B ${DEBUG_BUILD_DIR}"

    ${CMAKE} ${cmake_flags}
}

function build()
{
    if [ "$BUILD_TYPE" = "Release" ];
    then
        build_release
    elif [ "$BUILD_TYPE" = "Debug" ]
    then
        build_debug
    else
        build_release
        build_debug
    fi
}

function build_release()
{
    echo "start building the project in Release"
    ${CMAKE} --build ${RELEASE_BUILD_DIR} -j${CMAKE_PARALLEL} -v
    ${CMAKE} --build ${RELEASE_BUILD_DIR} --target install -j${CMAKE_PARALLEL} -v
}

function build_debug()
{
    echo "start building the project in Debug"
    ${CMAKE} --build ${DEBUG_BUILD_DIR} -j${CMAKE_PARALLEL} -v
    ${CMAKE} --build ${DEBUG_BUILD_DIR} --target install -j${CMAKE_PARALLEL} -v
}

function clean()
{
    echo "Clean the build and bin directory"
    rm -rf ${BUILD_DIR}
    rm -rf ${ROOT_DIR}/bin
}

while (( "$#" )); do
    COMMAND=$1
    case $COMMAND in
        build)
            build $BUILD_TYPE
            ;;
        generate)
            generate $BUILD_TYPE
            ;;
        clean)
            clean
            ;;
        esac
    shift
done