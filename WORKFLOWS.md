# GitHub workflows

The github workflows in this repository manage automatically building an publishing our container images.

# Workflows:

## `cli.yml`

This workflow builds images for the `psinode` and `psibase` CLI tools. 

### Input variables

* `version` - Must be set to the name of the git release tag of psinode on which the resulting CLI images should be based. 

### How to run

* This workflow can be manually run.
* This workflow is automatically triggered whenever a new release is published in the `psibase` repository.

## `_dispatcher.yml`

This workflow is the dispatcher for all other workflows except for `cli.yml`. It contains the logic for determining what other workflows to run, and how to parameterize them.

Depending on what files are changed, it may be necessary to run any of the following six workflow strategies:
  * 0: Build nothing
  * 1: run tool config (and all dependent workflows)
  * 2: run 2004 builder only
  * 3: run 2204 builder (and all dependent workflows)
  * 4: run both 2004 and 2204 builders (and all dependent workflows)
  * 5: run contributor only

### Input variables

None

### How to run

* This workflow is automatically triggered when there are changes to files in this repository. It is triggered both on a pull request and on merges into the main branch.

## `tool-config.yml`

This reusable workflow generates an image that packages up configuration files for various third-party tools used by other images. These configurations are from tools such as prometheus, grafana, etc., which can be helpful for node operators looking for more statistics about psinode. 

This workflow is also the only truly cross-platform image, currently, which works because we use QEMU emulation to build an arm-compatible image on an amd64-based runner. This strategy only works on this image because the image is very small, whereas other images are much too large for emulation to be feasible.

### Input variables

* `is_pr` - When `false` then the generated image is uploaded to `ghcr.io`. When `true` (when triggered by a pull request) then the generated image is uploaded as a local artifact to the github action with a retention time of 1 day.

### How to run

* This workflow is automatically triggered by the `_dispatcher.yml` workflow

## `builder-ubuntu.yml`

This reusable workflow generates the builder images, which are environments capable of building psibase from source. 

### Input variables

* `is_pr` - When `false` then the generated image is uploaded to `ghcr.io`. When `true` (when triggered by a pull request) then the generated image is uploaded as a local artifact to the github action with a retention time of 1 day.

* `ubuntu_version` - When set to either `"2004"` or `"2204"`, then the generated image will be based on the corresponding version of Ubuntu.

### How to run

* This workflow is automatically triggered by the `_dispatcher.yml` workflow

## `contributor.yml`

This reusable workflow generates the `psibase-contributor` image, which is used by the [psibase-contributor](https://github.com/gofractally/psibase-contributor/blob/main/.devcontainer/docker-compose.yml#L4) tool. It not only encapsulates an environment allowing one to build psibase from source, but it also includes the configs in the [tool-config](#tool-configyml) image, and additional build tools, to simplify the process of setting up a core psibase development environment.

### Input variables

* `is_pr` - When `false` then the generated image is uploaded to `ghcr.io`. When `true` (when triggered by a pull request) then the generated image is uploaded as a local artifact to the github action with a retention time of 1 day.

* `is_local_tools` - When `false`, then the workflow will fetch the latest tools image from the `ghcr.io/gofractally` registry. When `true` then this workflow will assume that a new tools image was generated as part of this change, and therefore will attempt to download the artifact from the github action.

* `is_local_tools` - When `false`, then the workflow will fetch the latest builder image from the `ghcr.io/gofractally` registry. When `true` then this workflow will assume that a new builder image was generated as part of this change, and therefore will attempt to download the artifact from the github action.

### How to run

* This workflow is automatically triggered by the `_dispatcher.yml` workflow
