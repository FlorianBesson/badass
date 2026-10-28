SUFFIX ?= fbesson

all: build

build:
	docker build -t router-${SUFFIX} -f router.dockerfile .
	docker build -t host-${SUFFIX} -f host.dockerfile .

down:
	- docker stop $$(docker ps -q)

up: 
	- docker run --name router -d --rm --privileged router-${SUFFIX}
	- docker run --name host -d  --rm host-${SUFFIX}

re: build down clean up
