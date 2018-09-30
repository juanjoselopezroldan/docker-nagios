#!make

# Base
SHELL:=/bin/bash

# Local conf
USER_LOCAL:=`whoami`

# Image Docker
NAME_REGISTRY:="juanjoselo/nagios:latest"

build:
	sudo chgrp ${USER_LOCAL} -R volumes
	sudo chmod 770 -R volumes
	docker build -f Dockerfile -t ${NAME_REGISTRY} .

start:
	sudo chgrp ${USER_LOCAL} -R volumes
	sudo chmod 770 -R volumes
	docker-compose -f docker-compose.yml up