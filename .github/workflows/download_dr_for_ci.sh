#!/bin/sh

version=$1
platform=$(./scripts/dr_platform.sh)
zip_file="dragonruby-for-ci-$version-pro-$platform.zip"
download_url="https://github.com/kfischer-okarin/dragonruby-for-ci/releases/download/$version/$zip_file"

curl -L -O $download_url
unzip $zip_file
chmod u+x ./dragonruby
