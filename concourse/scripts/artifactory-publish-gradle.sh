#!/bin/bash
set -o errexit
set -o xtrace

TARGET_DIR=$PWD/target
mkdir -p $TARGET_DIR

cd source

./gradlew artifactoryPublish

