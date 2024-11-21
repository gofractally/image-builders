# Docker images

This repo has the GitHub Actions necessary to build various docker images. Both linux/arm64 and linux/amd64 runners are used to produce images compatible with both architectures.

## ubuntu-2204-builder

An image based on Ubuntu 22.04 that contains an environment suitable for building Psibase from source.

Used by the `psibase-contributor` image.

## ubuntu-2404-builder

An image based on Ubuntu 24.04 that contains an environment suitable for building Psibase from source.

## tool-config

A [scratch](https://hub.docker.com/_/scratch)-based image that contains configuration files for various third-party tooling required by psibase contributor and other downstream images to allow them to display the admin-sys monitoring dashboards (e.g. Prometheus, Grafana, etc.).

This image has two variants: `http-tool-config` and `https-tool-config`.

The `http-*` version is meant to be used when you're running psinode on a server behind a reverse proxy, in which case the external tools connect to psinode locally over http.

The `https-*` version is meant to be used when you're connecting to psinode itself directly over https, which is most common in local development scenarios where you're not running psinode behind a reverse proxy, but you're still trying to connect over https. This version of the tooling image is used by default by the `psibase-contributor` image, which allows the development environment to expose psinode over https.

## psibase-contributor

An image based on `ubuntu-2404-builder` that also contains some external tools, environment variables, terminal completion, and other basic necessities used when developing Psibase.

This image is used by the psibase-contributor repository to simplify setting up a development environment inside a docker container.

## psinode

This image is used to run [psinode](https://docs.psibase.io/run-infrastructure/cli/psinode.html) from prebuilt psidk binaries in a docker container on Ubuntu 24.04. Psinode run in this way is exposed to the host on port 8080.

> Note: Teaching the various docker CLI options is outside the scope of this document, please see the [Docker CLI documentation](https://docs.docker.com/engine/reference/commandline/cli/) if you're confused about any of the flags.

If using this image to run psinode on your local machine, you can run it with:

```
docker run --rm --name psinode -p 8080:8080 -p 3000:3000 -p 9090:9090 --network psinode_network ghcr.io/gofractally/psinode:VERSION
```
> Note 1: If you don't need the [x-admin](https://docs.psibase.io/default-apps/x-admin.html) monitoring dashboards, then you only need to expose Psinode container port 8080.

> Note 2: Creating and using a custom docker network simply makes it easier to connect to the psinode container from other docker containers. This is helpful, for example, if you plan to interact with the container from a separate `psibase` container. If you only intend to interact with the container over TCP in the browser, then you don't need to use a custom docker network.

### Booting the chain

Running `psinode` sets up the psinode server. The psinode server can sync with other psinode servers, or run its own infrastructure. If you're running your own infrastructure, you will need to tell psinode to boot from scratch, rather than synchronizing with an existing network. To do this, you need to execute the `psibase boot` command, which can be done using the `psibase` CLI tool, in either of two ways.

The first way is to use the `psibase` tool that comes already in the `psinode` image:
```
docker exec PSINODE_CONTAINER_ID psibase boot -p myproducer
```

The second way is to use the separate `psibase` image on the same network as the psinode container. Documentation for how to use the psibase image is in the next section.

## psibase

This image is used to run [psibase](https://docs.psibase.io/run-infrastructure/cli/psibase.html) from prebuilt psidk binaries in a docker container on Ubuntu 24.04.

If you're using this tool to run commands on a `psinode` instance you started in a local docker container, you should run this image on the same custom docker network to allow you to connect to it using its container name. For example, the following is what the boot command would look like if `psinode_network` is the name of the custom docker network created for and used by the psinode container:

```
docker run --rm --network psinode_network ghcr.io/gofractally/psibase:PSINODE_VERSION -a http://PSINODE_CONTAINER_NAME:8080 boot -p myproducer
```

> Note: Ensure that the version of the Psibase image you use matches the version of the Psinode image. Different versions may be incompatible in unpredictable ways that could cause silent failures/bugs.

The `psibase` CLI tool may remotely connect to any publicly exposed psinode using the -a flag, for example:

```
psibase -s <PRIV_KEY> -a http://<PSINODE_URL>:8080 create bob --key <PUBKEY> --sender alice
```

# Github workflows

For more information on the CI/CD workflows that are responsible for generating and uploading all of the aforementioned docker images, see [WORKFLOWS.md](./WORKFLOWS.md).
