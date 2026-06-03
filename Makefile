SILENT :

update-dependencies:
	docker pull postgres:16-alpine

compose-build:
	docker compose build

compose-up:
	docker compose up

build:
	docker build -t cachet/docker .
