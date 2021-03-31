## HIGH LEVEL FLOW

1. Create a job which runs a task which assembles/builds your application's code.
2. Push to an `enterprise-pipeline-api` resource definition for the environment. You will provide a path to a script which performs the deployment steps (e.g. `cf push`).
3. EP will determine the PCF org and space based on the `org` and `buildTeamName` paramaters defined in the resource. It will then hijack the container running in Concourse and execute the script which you provide which contains all `cf` commands necessary to deploy your app (e.g. `cf create service ...`, `cf push`)

## How is the space name where the app is deployed determined?

The space name will be determined based on the combination of the teamName, org name and division supplied in the resource definition for an environment.

For example to deploy an app into the ABC-CAC-DEV space in GSD-CAC-DEV you would have the following attributes:

```yml
json:
  ...
  teamName: "ABC"
  org: "GSD-CAC-DEV"
  division: "CAC"
```

EP will construct the space name by concatenating `{teamName}-{division}-{environment}` where `{environment}` is taken as the last part of the org name.

### What if my space name does not match this pattern?

There are 2 cases here.

1) Space name is a simple name like "ABC" and does not contain the division or environment.

In this case you can specify the `ignoreDivisionAndEnvironmentInSpaceName` to be true under the `json` section of the resource configuration and the space name will be taken as simply the team name.

For example if your space name is "ABC" and exists in the org "GSD-CAC-DEV" you would have the following attributes:

```yml
json:
  teamName: "ABC"
  org: "GSD-CAC-DEV"
  division: "CAC"
  ignoreDivisionAndEnvironmentInSpaceName: true
```

2) Space name ends with a suffix that does not match the environment name. For example space name is ABC-CAC-PARALLEL in org ABC-CAC-UAT.

In this case you can specify the `spaceSuffixOverride` parameter under the `json` section of the resource definition with the custom space name suffix.

For example if your space name is "ABC-CAC-PARALLEL" and exists in org "GSD-CAC-DEV" you would have the following attributes:

```yml
json:
  teamName: "ABC"
  org: "GSD-CAC-DEV"
  division: "CAC"
  spaceSuffixOverride: "PARALLEL"
```

# Enterprise Pipeline PROD Deployment Demo

Example Spring Boot application with deployment all the way up to PROD using Enterprise Pipeline.

For non Java/Spring Boot applications please see the various example Concourse pipelines for those project types. The core structure of how the deployment works using Enterprise Pipeline will be the same for all languages/frameworks.

This project assumes a branch-per-environment model where 'develop' branch is committed to by developers and 'acceptance', 'uat' and 'master' branches represent code that should exist in Acceptance, UAT and PROD environments respectively.

## Features

- Deployment to Acceptance, UAT and PROD
- Creation of MySQL database service
- Passing environment variables
- Jobs for restarting applications in UAT and PROD

## How it works

For non-PROD deployments the process is the same as the current Enterprise Pipeline approach. 

**For PROD deployments** 

An email will be sent to the project team (as specified in the 'teamEmail' parameter in the push resources). The project team should follow the link provided to submit their change ticket number for the deployment which will then be validated in order to allow the deployment to continue.

The change will be validated for approval, being in the change window and containing the Concourse URL of the job in its implementation plan. If the change is successfully validated a response of "Approved" will be shown when submitting and the job will be allowed to continue. If the change is rejected the reason for rejection will be shown as a respons and the Concourse job will be terminated.

**Automated Change Tickets** 

Enterprise Pipeline can automatically create **BAU** Change Tickets on your behalf and proceed with the deployment when Change Ticket is approved and within Change Window.

To enable this feature, add property `changeticketFile` below the `teamEmail` in your json body of the enterprise-pipeline resource
```yml
    teamEmail: "example@manulife.com"
    changeticketFile: "target/changeTicketFile.json"
```
The value should point to a json file which contains the template for creating change ticket.
Below is an example
```json
{
  "correlation_id": "1583838983",
  "start_date": "2020-01-01 09:00:00",
  "end_date": "2020-01-01 17:00:00",
  "u_dal_ci": "DAL - Network Services",
  "assignment_group": "IFS_PMA-IPC-CAN",
  "cmdb_ci": "ABAK - sl",
  "u_ml_impact": "Asia,Canada",
  "assigned_to": "Divya Nair",
  "requested_by": "Pranay Sharma",
  "backout_plan": "QA Test Backout Plan",
  "description": "Test Valid Impact",
  "implementation_plan": "Please Trigger Concourse jobs: https://concourse.platform.manulife.io/teams/GEES/pipelines/gspe-concourse-service-now-integration/jobs/change-ticket",
  "justification": "QA test Justification",
  "short_description": "QA Test Valid Impact",
  "test_plan": "QA validate Test Plan",
  "u_outage_description": "QA Validate Outage description",
}
```
**Please note** correlation_id must be always unique, start_date must be always in future and end_date must be always after end_date.
Its recommended to calculate these field dynamically in your assemble / deploy scripts 

Below sample script creates a change ticket 10 minutes in future

```bash
CORRELATION=`date +%s`
STARTDATE=$(env TZ=America/New_York date --date='+600 seconds' +"%Y-%m-%d %H:%M:%S")
ENDDATE=$(env TZ=America/New_York date --date='+7200 seconds' +"%Y-%m-%d %H:%M:%S")

sed -i "s/{start_date}/$STARTDATE/g" changeTicketFile.json
sed -i "s/{end_date}/$ENDDATE/g" changeTicketFile.json
sed -i "s/{correlation_id}/$CORRELATION/g" changeTicketFile.json
```

After the completion of the job, enterprise pipeline will close the change ticket with proper status code

**IMPORTANT**

The Implementation Plan in your change must contain the **exact** Concourse URL of the job you are executing, **without** the `/builds/[buildNumber]` suffix.

Example implementation plan:

> Deploy application via pipeline job: https://concourse.platform.manulife.io/teams/GEES/pipelines/my-application-pipeline/jobs/deploy-prod

The plan may contain multiple Concourse URLs if the same change is being used to trigger multiple different pipeline jobs.

You may also approve Concourse jobs that are listed in the Backout Plan of your change.

As a last resort fallback in case the self-serve approval does not work, the team may reply-all to the email with a link to their change ticket for the deployment. The GSPE Platform Requests team can then click the secondary link in the email to approve the deployment to proceed.

**If you are not receiving the emails your email is probably not synced properly with Domino servers. Open an incident ticket and assign to messaging team specifying that you are not recieving emails through mail.manulife.com**

The Enterprise Pipeline will execute a shell script as provided in the resource configuration by the `deploy_script` parameter. This script should contain any `cf create service ...`, `cf set-env ...` and `cf push` commands for preparing and deploying the application.

## TL;DR

Add custom resource type for Enterprise Pipeline API:

```yml
resource_types:
- name: enterprise-pipeline-api
  type: docker-image
  source:
    repository: docker.artifactory.platform.manulife.io/concourse-enterprise-pipeline-http-api-resource
    tag: latest
```

Create a deployment resource:

```yml
- name: cf-push-prod
  type: enterprise-pipeline-api
  source:
    api: fly
    method: POST
    debug: true
    ssl_verify: false
    json:
      buildTeamName: "{BUILD_TEAM_NAME}"         #populated automatically
      buildId: "{BUILD_ID}"                      #populated automatically
      buildName: "{BUILD_NAME}"                  #populated automatically
      buildJobName: "{BUILD_JOB_NAME}"           #populated automatically
      buildPipelineName: "{BUILD_PIPELINE_NAME}" #populated automatically
      org: {{CF_PROD_ORG}}

      #Full path to script which will execute 'cf push' and optionally 'cf create-service' commands
      #the 'source' folder name here should match with the name specified in the 'get' in the src-dev git resource below
      deploy_script: "source/concourse/scripts/push-prod.sh"

      #Specifies the PCF environment
      division: "CAC"

      #This should just be the same as the name of this resource
      buildTaskName: "cf-push-prod"

      #Team or project lead email for sending deployment instructions to
      teamEmail: "example@manulife.com"

      #Path to the change ticket template
      changeticketFile: "gitfolder/changeTicketFile.json"

    env_vars:
      MY_ENV_VAR: {{MY_ENV_VAR}}
```

Create a deploy script:

```bash
#!/bin/bash
set -o errexit
set -o xtrace

#any other cf commands such as 'cf create-service' can go here
cf create-service p.mysql db-small mongo-atlas-migrate-demo-db

#current script path is /source/concourse/scripts/push.sh
#cd back to the root and then into the 'target' folder created in assemble.sh where the build folder and manifest.ymls were copied
cd ../../../target

#current directory should contain the manifest-prod.yml file

#If you do not need to set environment variables then you can just do 'cf push..' without the --no-start option
cf push -f manifest-prod.yml --no-start
cf set-env mongo-atlas-migrate-demo MY_ENV_VAR $MY_ENV_VAR
cf start mongo-atlas-migrate-demo
```

Create a deployment job:

```yml
- name: deploy-prod
  serial: true
  public: true
  plan:
  - in_parallel:
    - get: source
      resource: src-master
      passed: [push-master]
      trigger: true
  - task: assemble
    file: source/concourse/tasks/assemble.yml
    params:
      TERM: xterm
  - put: cf-push-prod
```

Create an assemble task and script:

assemble.yml

```yml

---
platform: linux

image_resource:
  type: registry-image
  source:
    repository: docker.artifactory.platform.manulife.io:443/java-ci
    insecure_registries: ["docker.artifactory.platform.manulife.io:443"]

inputs:
- name: source

outputs:
- name: target

run:
  path: source/concourse/scripts/assemble.sh

```

assemble.sh

```bash
#!/bin/bash
set -o errexit
set -o xtrace

TARGET_DIR=$PWD/target
mkdir -p $TARGET_DIR

cd source

gradle assemble

cp -R build $TARGET_DIR/
cp manifest-acceptance.yml $TARGET_DIR/
cp manifest-uat.yml $TARGET_DIR/
cp manifest-prod.yml $TARGET_DIR/
```


# DR

DR Plan Components (https://confluence.manulife.io/display/PE/DR+Plan+Component+Templates)

In a DR scenario the services for enterprise pipeline will be deployed in the CAE PCF environment. To make sure your pipeline connects to the DR instance of these services during deployment you must specify the `env: DR` option in your enterprise-pipeline-http-api resource definitions:

```yml
- name: cf-push-prod
  type: enterprise-pipeline-api
  source:
    # Specify DR instance
    env: DR
    api: fly
    method: POST
    debug: true
    ssl_verify: false
    json:
      ...
```

Not that you do NOT need to change the org or space names for DR deployments as the org and space names are the same between the primary and DR regions in PCF.

### Deploying to PROD and DR with the same job

For CAC it is reccommended that you always deploy your application to DR when deploying to production.

This can be done by simply `put`ing to both your prod and DR deployment resources in the same jobs:

```yml
- name: deploy-prod
  serial: true
  public: true
  plan:
  - in_parallel:
    - get: source
      resource: src-master
      passed: [push-master]
      trigger: true
  - task: assemble
    file: source/concourse/tasks/assemble.yml
    params:
      TERM: xterm
  - put: cf-push-prod
  - put: cf-push-prod-dr
```

If you want to deploy to DR, but only have the app actually running in production, you can modify your `cf push` command in your DR deployment script to do a push without starting the app:

```bash
cf push -f manifest-prod-dr.yml --no-start
```

See the full pipeline example in the `concourse` folder in this repository for a full example.

**Please note** that the org/space names remain the same (e.g. containing CAC or EAS) in the DR region and should *not* be changed to CAE or SEA in your resource configuration. 

# Architecture/Flow

![https://git.platform.manulife.io/geesoffice/mongo-atlas-migrate-demo/blob/master/EP%20Architecture.png](EP Architecture.png)
