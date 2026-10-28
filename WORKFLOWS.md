# GitHub workflows

The github workflows in this repository manage automatically building an publishing our container images.

# Workflows:

## `cli.yml`

This workflow builds images for the `psinode` and `psibase` CLI tools. 

### Input variables

* `version` - The tag of the resulting images. When `psidk_run_id` is empty, it must be the name of the psibase git release tag whose `psidk-ubuntu-2204` asset the images are built from.
* `psidk_run_id` (optional) - The id of a psibase Actions run that uploaded a `psidk-ubuntu-2204` artifact.
  * When empty, the images are built from the release asset and pushed to GHCR as `psinode:<version>` and `psibase:<version>` multi-arch manifests.
  * When set, the images are built from that run's artifact and nothing is pushed to GHCR. Each architecture's images are uploaded as docker-loadable run artifacts `psinode-<arch>-image` and `psibase-<arch>-image`, tagged `psinode:<version>-<arch>` and `psibase:<version>-<arch>`. Downloading the artifact requires the `PSIBASE_ARTIFACT_TOKEN` repository secret, a token with read access to psibase Actions artifacts.

### How to run

* This workflow can be manually run.
* This workflow is automatically triggered with only `version` whenever a new release is published in the `psibase` repository.

## `_dispatcher.yml`

This workflow is the dispatcher for all other workflows except for `cli.yml`. It contains the logic for determining what other workflows to run, and how to parameterize them.

An image must be rebuilt if either its dependent files have changed, or if it depends on an image whose dependent files have changed. The images must always be built in an order that respects their dependencies. This workflow maintains this logic.

### Input variables

None

### How to run

* This workflow is automatically triggered when there are changes to files in this repository. It is triggered both on a pull request and on merges into the main branch.

## `tool-config.yml`

This reusable workflow generates an image that packages up configuration files for various third-party tools used by other images. This image has largely been deprecated and is currently only used to add some sample psinode configuration files into the final image.

### Input variables

None

### How to run

* This workflow is automatically triggered by the `_dispatcher.yml` workflow

## `builder-ubuntu.yml`

This reusable workflow generates the builder images, which are environments capable of building psibase from source. 

### Input variables

* `ubuntu_version` - When set to `"2204"`, `"2404"`, or `"2604"`, then the generated image will be based on the corresponding version of Ubuntu.

### How to run

* This workflow is automatically triggered by the `_dispatcher.yml` workflow

## `contributor.yml`

This reusable workflow generates the `psibase-contributor` image, which is used by the [psibase-contributor](https://github.com/gofractally/psibase-contributor/blob/main/.devcontainer/docker-compose.yml#L4) tool. It not only encapsulates an environment allowing one to build psibase from source, but it also includes the configs in the [tool-config](#tool-configyml) image, and additional build tools, to simplify the process of setting up a core psibase development environment.

### Input variables

* `new_tools` - When true, it means that a new tools image is available as of this job. Therefore, when the contributor build runs, it will use this new image by downloading it either from the job artifact (in the case of a pull request) or from a published GitHub container registry artifact (in the case of a merge).

* `new_base` - When true, it means that a new builder image is available as part of this job. Therefore, when the contributor build runs, it will use this image by downloading it either from the job artifact (in the case of a pull request) or from a published GitHub container registry artifact (in the case of a merge).

### How to run

* This workflow is automatically triggered by the `_dispatcher.yml` workflow
