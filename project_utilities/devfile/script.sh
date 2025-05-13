#!/bin/bash
printenv
sudo dnf update -y
sudo dnf install bzip2-devel -y
sudo dnf install python3.12 python3.12-pip -y
pip3.12 install --upgrade pip
pip3.12 install -r $SCRIPT_PATH/dev-requirements.txt