VERSION ?= 1.0.0-SNAPSHOT
CONTAINER_NAME ?= vsftpd

.PHONY: build
build:
	docker build . -t morarom/vsftpd-alpine -t morarom/vsftpd-alpine:${VERSION}

.PHONY: 
push:
	docker push morarom/vsftpd-alpine


.PHONY: run
run:
	docker run -d --name ${CONTAINER_NAME} -p 20-22:20-22 -p 21100-21110:21100-21110 morarom/vsftpd-alpine:${VERSION}


.PHONY: start
start:
	docker start ${CONTAINER_NAME}


.PHONY: stop
stop:
	docker stop ${CONTAINER_NAME}


.PHONY: clean-container
clean-container:
	docker container rm ${CONTAINER_NAME}


.PHONY: clean-images
clean-images:
	docker image rm morarom/vsftpd-alpine morarom/vsftpd-alpine:${VERSION}


.PHONY: clean-all
clean-all: clean-container clean-images


.PHONY: up
up: build run

.PHONY: down
down: stop clean-container
