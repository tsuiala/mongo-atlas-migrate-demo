#!/bin/bash
set -o errexit
set -o xtrace

TARGET_DIR=$PWD/target
mkdir -p $TARGET_DIR

cd source
GITHASH="$(git rev-parse HEAD)"
STARTDATE=$(env TZ=America/New_York date --date='+500 seconds' +"%Y-%m-%d %H:%M:%S")
ENDDATE=$(env TZ=America/New_York date --date='+7200 seconds' +"%Y-%m-%d %H:%M:%S")

sed -i "s/{start_date}/$STARTDATE/g" changeTicketFile.json
sed -i "s/{end_date}/$ENDDATE/g" changeTicketFile.json
sed -i "s/{correlation_id}/$GITHASH/g" changeTicketFile.json

gradle assemble

cp -R build $TARGET_DIR/
cp manifest-*.yml $TARGET_DIR/
cp changeTicketFile.json $TARGET_DIR/