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

An image must be rebuilt if either its dependent files have changed, or if it depends on an image whose dependent files have changed. The images must always be built in an order that respects their dependencies. This workflow maintains this logic.

### Input variables

None

### How to run

* This workflow is automatically triggered when there are changes to files in this repository. It is triggered both on a pull request and on merges into the main branch.

## `tool-config.yml`

This reusable workflow generates an image that packages up configuration files for various third-party tools used by other images. These configurations are from tools such as prometheus, grafana, etc., which can be helpful for node operators looking for more statistics about psinode. 

### Input variables

None

### How to run

* This workflow is automatically triggered by the `_dispatcher.yml` workflow

## `builder-ubuntu.yml`

This reusable workflow generates the builder images, which are environments capable of building psibase from source. 

### Input variables

* `ubuntu_version` - When set to either `"2204"` or `"2404"`, then the generated image will be based on the corresponding version of Ubuntu.

### How to run

* This workflow is automatically triggered by the `_dispatcher.yml` workflow

## `contributor.yml`

This reusable workflow generates the `psibase-contributor` image, which is used by the [psibase-contributor](https://github.com/gofractally/psibase-contributor/blob/main/.devcontainer/docker-compose.yml#L4) tool. It not only encapsulates an environment allowing one to build psibase from source, but it also includes the configs in the [tool-config](#tool-configyml) image, and additional build tools, to simplify the process of setting up a core psibase development environment.

### Input variables

* `new_tools` - When true, it means that a new tools image is available as of this job. Therefore, when the contributor build runs, it will use this new image by downloading it either from the job artifact (in the case of a pull request) or from a published GitHub container registry artifact (in the case of a merge).

* `new_base` - When true, it means that a new builder image is available as part of this job. Therefore, when the contributor build runs, it will use this image by downloading it either from the job artifact (in the case of a pull request) or from a published GitHub container registry artifact (in the case of a merge).

### How to run

* This workflow is automatically triggered by the `_dispatcher.yml` workflow
