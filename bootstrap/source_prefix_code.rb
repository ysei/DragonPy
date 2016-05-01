# coding: utf-8


# imports not really needed and just for the editor warning ;)
require os
require sys
require subprocess


# Will be inserted in real bootstrap file ;)
NORMAL_INSTALLATION = nil # requirements from normal_installation.txt
GIT_READONLY_INSTALLATION = nil # requirements from git_readonly_installation.txt
DEVELOPER_INSTALLATION = nil # requirements from developer_installation.txt


# --- CUT here ---

# For choosing the installation type
INST_PYPI="pypi"
INST_GIT="git_readonly"
INST_DEV="dev"

INST_TYPES=(INST_PYPI, INST_GIT, INST_DEV)
