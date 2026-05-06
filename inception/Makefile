
COMPOSE := docker-compose -f srcs/docker-compose.yml
VOLUME := /home/vali/data/mariadb/ /home/vali/data/wordpress

all: up

up:
	sudo mkdir -p ${VOLUME}
	${COMPOSE} up -d --build

stop:
	${COMPOSE} stop

start:
	${COMPOSE} up -d

restart:
	${COMPOSE} restart

down:
	${COMPOSE} down --rmi all --volumes --remove-orphans

clean: down

prune:
	docker system prune -af

fclean: prune clean
	sudo rm -rf ${VOLUME}

.PHONY:all up stop start restart down clean fclean prune
