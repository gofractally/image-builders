# image-builders

This repo has the GitHub Actions necessary to build various docker images.

## ubuntu-2004-builder

An image based on Ubuntu 20.04 that contains an environment suitable for building Psibase from source.

## ubuntu-2204-builder

An image based on Ubuntu 22.04 that contains an environment suitable for building Psibase from source.

## psibase-contributor

An image based on `ubuntu-2204-builder` that also contains some external tools, environment variables, terminal completion, and other basic necessities used when developing Psibase.

This image is used by the psibase-contributor repository to simplify setting up a development environment inside a docker container.
