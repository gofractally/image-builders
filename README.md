# image-builders

This repo has the GitHub Actions necessary to build various docker images.

## ubuntu-2004-builder

An image based on Ubuntu 20.04 that contains an environment suitable for building Psibase from source.

## ubuntu-2204-builder

An image based on Ubuntu 22.04 that contains an environment suitable for building Psibase from source.

## tool-config

A [scratch](https://hub.docker.com/_/scratch)-based image that contains configuration files for various third-party tooling required by psibase contributor and other downstream images to allow them to display the admin-sys monitoring dashboards.

## psibase-contributor

An image based on `ubuntu-2204-builder` that also contains some external tools, environment variables, terminal completion, and other basic necessities used when developing Psibase.

This image is used by the psibase-contributor repository to simplify setting up a development environment inside a docker container.
