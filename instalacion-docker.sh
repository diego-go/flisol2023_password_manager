#!/bin/bash

## install docker

echo "Fetching Docker installation script..."
curl -fsSL https://get.docker.com -o get-docker.sh

echo "Installing Docker..."
sh get-docker.sh

## install docker-compose

echo "Fetching docker-compose..."
curl -L https://github.com/docker/compose/releases/download/v2.11.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

##
echo "Verifying paths..."
whereis -b docker
whereis -b docker-compose