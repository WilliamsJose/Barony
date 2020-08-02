#!/bin/bash

# 1) Fetch the dependencies

if [ -z $DEPENDENCIES_ZIP_KEY ]; then
	echo "Error! No key provided for encrypted dependencies zip. Aborting."
	exit 1
fi
if [ -z $DEPENDENCIES_ZIP_IV ]; then
	echo "Error! No IV provided for encrypted dependencies zip. Aborting."
	exit 1
fi

# 1.a) Create dependencies directory.
mkdir ../dependencies
cd ..
export DEPENDENCIES_DIR=$(pwd)/dependencies/
cd dependencies

# 1.b) Fetch the encrypted dependencies zip.
wget https://github.com/TurningWheel/Barony/releases/download/ci_deps_1.0/dependencies_linux.zip.enc -O dependencies.zip.enc
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "Fetching encrypted dependencies zip failed. Aborting."
  exit $RESULT
fi

# 1.c) Provision encrypted dependencies zip. (password protected, pass in key & IV through an environment variable!!)
openssl aes-256-ctr -d -in dependencies.zip.enc -out dependencies.zip -K $DEPENDENCIES_ZIP_KEY -iv $DEPENDENCIES_ZIP_IV
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "Decrypting dependencies zip failed. Aborting."
  exit $RESULT
fi
unzip dependencies.zip
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "Unzipping dependencies zip failed. Aborting."
  exit $RESULT
fi

# 1.d) Set dependencies search paths.
export STEAMWORKS_ROOT="${DEPENDENCIES_DIR}/steamworks_sdk/"
export STEAMWORKS_ENABLED=1
export FMOD_DIR="${DEPENDENCIES_DIR}/fmodapi/api/"

# 2) Build from source

mkdir -p ../build/release
cd ../build/release

export OPTIMIZATION_LEVEL="-O2"
export CXX=clang++
export CC=clang
cmake -DCMAKE_BUILD_TYPE=Release -DFMOD_ENABLED=ON -G "Unix Makefiles" ../..
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "CMAKE generation failed. Aborting."
  exit $RESULT
fi

make -j
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "Compilation failed. Aborting."
  echo "But first, here's your Config.hpp!"
  cat ../../src/Config.hpp
  exit $RESULT
fi