#!/bin/bash
set -ex

rm -rf testBin
stack run | tar -xvf -
pushd testBin
make
./testBin
popd
