#!/bin/bash

# # Replace GEES with the team name for your space
# # fly --target manulife-ci login --team-name GEES --concourse-url https://concourse.platform.manulife.io --insecure

# # Replace 'mongo-atlas-migrate-demo' with your application's pipeline name
# fly -t manulife-ci destroy-pipeline -p mongo-atlas-migrate-demo

# fly -t manulife-ci set-pipeline -p mongo-atlas-migrate-demo -c pipeline.yml -l config.yml

# fly -t manulife-ci unpause-pipeline -p mongo-atlas-migrate-demo

#!/bin/bash

# Replace GEES with the team name for your space
# fly --target manulife-ci login --team-name GEES --concourse-url https://concourse.platform.manulife.io --insecure

# Replace 'mongo-atlas-migrate-demo' with your application's pipeline name
fly -t prod-main destroy-pipeline -p mongo-atlas-migrate-test

fly -t prod-main set-pipeline -p mongo-atlas-migrate-test -c pipeline.yml -l config.yml

fly -t prod-main unpause-pipeline -p mongo-atlas-migrate-test
