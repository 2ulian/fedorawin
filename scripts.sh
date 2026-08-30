#!/bin/sh

# build locally
sudo podman build -t localhost/fedora-image:latest -f Containerfile .
