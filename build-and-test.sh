#!/bin/bash

docker build --rm -t versionish/versionish:1.0.0 .
docker build --rm -t versionish/versionish-tests:1.0.0 -f Dockerfile.bats .
docker run --name versionish-tests -it --rm -v $(pwd)/tests:/tests:rw versionish/versionish-tests:1.0.0 --formatter pretty --recursive .

