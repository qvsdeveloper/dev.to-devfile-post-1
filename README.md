# Introduction
This is a true beginner's guide to following [ryanback-AWS's Repost article](https://repost.aws/articles/ARBTATztMgQOeYyMZ9IAmxDw/configuring-codecatalyst-dev-environments), along with our experience using the AWS CodeCatalyst Free Tier to create a developer environment configured for dbt development with AWS Redshift as its target and Visual Studio Code as the preferred IDE. It is 2025, and the repost article dates back to 2023. We found the process of understanding Devfile and AWS CodeCatalyst difficult, and our understanding of the documentation lacking, so we created this post to aid our own understanding and share with the Devfile CodeCatalyst community.

My background: I am the Principal Data Architect for a manufacturing company near Philadelphia. One of my many tasks is to support the desktop development environments for the developers that I hope will contribute to the various projects I work on. This involves installing Python and other packages such as python-poetry, setting environment variables, managing packages and configuring other settings on each workspace. I would love to define the workspace in the repository our developers are using, to enable them to start coding sooner with the right environment for our project. CodeCatalyst and Devfile look to be an alternative to GitHub Codespaces and Devcontainers.

Also involved in this effort is Satya Kesanakurty, a DevOps specialist who is extremely knowledgable in creating deployment pipelines bitbucket, a bash scripting genius, and overall Linux super user. 

We collectively find learning DevFile and CodeCatalyst a humbling experience. 

Using the use case walkthrough from the article referenced above, we created a repository on [github qvsdeveloper/dev.to-devfile-post-1](https://github.com/qvsdeveloper/dev.to-devfile-post-1) to test what we learned and have a few things to share:

# Getting Started with DevFile
* how to iterate and setup your Devfile environment
* what changes require you to delete the dev environment
* where to look for log files
* what to expect to not work

## Getting Started with devfile.yaml

Devfile is a standard external to AWS with its own [documentation site] (https://devfile.io/docs/2.0.0/what-is-a-devfile), with AWS Codecatalyst supporting version 2.0.0. Ensure that your devfile specifies schemaVersion: 2.0.0

The critical section to get right the first time is the components section. In this section of the Devfile we will specify a container in which AWS will host and then the VS Code editor will connect to and open a remote terminal session.  Ensure that the container image is supported. We were successful with the following:
* public.ecr.aws/aws-mde/universal-image:latest
* public.ecr.aws/aws-mde/universal-image:3.0
* public.ecr.aws/aws-mde/universal-image:4.0

Note that for some reason the latest points to image 3.0 and the aws-mde user on the public.ecr.aws does not publish any information about it. It would be nice to know if and when there might be a version 5.0.

In the env key of container I specified an environment variable called SCRIPT_PATH and I hard coded the path from the /projects folder to the repository's folder I created for Devfile scripts.  I did this to demonstrate how to create env variables, which are also useful for passing in credentials and secrets.  I use the environment variable, SCRIPT_PATH,  for convenience in both the devfile.yaml and the script.sh file.  If the name of the repository changes you will need to update this path to match your environment.

## what changes require you to delete the dev envionment


Delete and recreate environment in CodeCatalyst's My Dev Environments whenever a change is made to the component's container section of the devfile.yaml. If the change is made while in the dev environment, make sure to git commit and push the change back to the CodeCatalyst repository. Then delete the environment and create a new dev environment for VS Code. This process takes a few minutes.  When in doubt delete and start over.

![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/4hlpf7jifuq2yi37y8kx.png)
Do not be afraid to delete the environment, you will be typing delete a lot!

Changes 

## what to check after starting a dev environment

Immediately or after any major change to the devfile check the status and check the logs!  They are in the directory: /aws/mde/logs
In that directory there should be a devfile.log and if any commands were specified there will be a devfileCommand.log

### what to look for in the devfile.log file
one specific message to look for is "WRN Fallback devfile started". This means that the standard image devfile is in use and no customizations were applied. This indicates a format issue with the devfile.yaml file or a problem in the components section.

### the devfileCommand.log file
The devfileCommand.log will contain the output of the commands section of the devFile.yaml which will be the information normally observed at the command line when installing packages or configuring the system manually.

### check the status with the mde status command
Another way to quickly check the devfile status is with the /aws/mde/mde status command if "status": "STABLE" with no location then the devfile was not properly applied and the fallback devfile in effect.  if the status is stable with a location, then the Devfile was successfully applied.

success example:
`
{
    "status": "STABLE",
    "location": "devto-article/devfile.yaml"
}
`
failure example:
`
{
    "status": "STABLE"
}
`
## How to quickly iterate with Devfile
Quickly delete and recreate the dev environment until the components section of the Devfile is working. Check the devfile.log and mde status for success, like the success example above.  The next step is to focus on the commands and events section of the Devfile. Changes to this section can be made without deleting the dev environment.  The commands section can be rerun within the same dev environment by using the /aws/mde/mde command <command id>, replacing the <command id> with the value in the command: -id key of the devfile.yaml.

## what to expect to not work
* We currently are not using SSO with CodeCatalyst
* Use of VPC is not supported or working currently with opening the dev environment with VS Code.

# Overview of our devfile project
* Prepare the environment for dbt-redshift
* Install dbt-redshift to the 3.12 python environment
* Use the default vpc
* Open environment in VS Code

The goal of my Devfile project is to create an environment for dbt-redshift on AWS development. We created a repository on github to hold our project reference in this section: https://github.com/qvsdeveloper/dev.to-devfile-post-1


my devfile.yaml in the root of the project directory:

Here is my example defile.yml:

```
schemaVersion: 2.0.0
metadata:
  name: devto-article
  version: 1.0.1
  displayName: devto-article
  description: devfile for article
  tags: ["devto"]
components:
  - name: devto
    container:
      image: public.ecr.aws/aws-mde/universal-image:3.0
      env:
        - name: SCRIPT_PATH
          value: /projects/dev.to-devfile-post-1/project_utilities/devfile
commands:
  - id: run-script
    exec:
      component: devto
      commandLine: "bash ${SCRIPT_PATH}/script.sh"
      workingDir: "${SCRIPT_PATH}"
events:
  postStart:
    - run-script
```

In this devfile.yaml I am setting the schemaVersion to 2.0.0 as this is required.

## metadata
The metadata section provides informational data that isn't used anywhere as far as I can tell.

## components
The components section is where the universal-image is specified, and I create and set an environment variable with a path that works for my project. I my repo I created a folder tree to project_utilities/devfile so I could store a script.sh and dev-requirements.txt file.

Any change to the components section requires deletion and recreation of the dev environment. 

The name of the component is referenced later in the commands section.
### container
This section defines the container in which vs code will remotely connect to and host the project. It will also provide a bash terminal.

#### image
In the image section I have only had success using the universal-image from aws-mde and redhat's universal-image. However, Redhat requires a subscription to update packages. You can't just use any container package like quay.io/devfile/python:latest because it will result in a default image.

#### env
In the environment section of the container it is useful to set environment variables. In my example a set an environment variable called SCRIPT_PATH to a location in my repository which I will use in my post install script file.

## commands
The commands section define commands that can be run. The id field is the name of the command and is referenced in the events section of the devfile. In the commands section under exec the value of the component must match the name assigned to the component (line 9).  The commandLine (line 19) runs a bash script called script.sh and sets the working directory to be the environment variable called $SCRIPT_PATH (line 20)

## events
In the events section the postStart command is calling run-script (line 23) this matchs the command defined by id in the command section (line 16).
The postStart event means it is run every time the dev environment is started. The script takes a few moments to run so on first use the script may not complete before the devfile users is able to us the command prompt.

# script.sh

```
#!/bin/bash
printenv
sudo dnf update -y
sudo dnf install bzip2-devel -y
sudo dnf install python3.12 python3.12-pip -y
pip3.12 install --upgrade pip
pip3.12 install -r $SCRIPT_PATH/dev-requirements.txt
```

# dev-requirements.txt

```
dbt-redshift==1.8.1
```

# project tree
```
.
├── devfile.yaml
├── project_utilities
│   └── devfile
│       ├── dev-requirements.txt
│       └── script.sh
└── README.md
```
# TODO
next steps in our devfile project:
* add our dbt-redshift project code to our repository
* configure additional environment variables to reference in our dbt project for redshift connections, database names, schema information and secrets
* configure our redshift database security groups to allow connections from the external IP addresses in use by the Dev environment in us-west-1.

# Resources
[This Project Github Repository](https://github.com/qvsdeveloper/dev.to-devfile-post-1)
[Repost Article]( https://repost.aws/articles/ARBTATztMgQOeYyMZ9IAmxDw/configuring-codecatalyst-dev-environments)
[devfile 2.0.0 docs](https://devfile.io/docs/2.0.0/benefits-of-devfile)
[Amazon CodeCatalyst Dev Environments](https://codecatalyst.aws/explore/dev-environments)
[devfiles vs devconatiner](https://www.daytona.io/dotfiles/devfiles-development-containers-understanding-differences)
