#!/usr/bin/env bash

# Build image
docker build --tag=my-python-app .

# List docker images
docker image ls

# Run flask app
docker run -p 8000:5000 my-python-app
