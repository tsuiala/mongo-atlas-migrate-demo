#!/bin/bash
set -o errexit
set -o xtrace

#any other cf commands such as 'cf create-service' can go here
cf create-service mongodb-odb standalone_small standalone-test -c '{"version":"3.6.5-ent"}'

#current script path is /source/concourse/scripts/push.sh
#cd back to the root and then into the 'target' folder created in assemble.sh where the build folder and manifest.ymls were copied
cd ../../../target

#current directory should contain the manifest-dev.yml file

#If you do not need to set environment variables then you can just do 'cf push..' without the --no-start option
cf push -f manifest-dev.yml --no-start
cf set-env mongo-atlas-migrate-demo MY_ENV_VAR $MY_ENV_VAR
cf start mongo-atlas-migrate-demo