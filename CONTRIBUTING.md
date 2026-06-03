# Contribution Guidelines

## Creating issues

Feature requests and bug reports should be made by using the [issue tracker](https://github.com/cachethq/Docker/issues). This "Dockerized" version of Cachet is maintained by members the Cachet community, so support issues will be address on a best effort basis.

**Always be respectful.** Organization members reserve the right to lock topics if they feel necessary.

## Branch and Tag Structure

* `main`: Cachet with the upstream Cachet `3.x` codebase.
* Minor version branches
* Tags are used to denote a Cachet release, and correspond to Docker Hub automatic builds.

# Releasing a new Cachet Docker image version

The below example shows creating a `v3.0.0` release.

```
git checkout main
git checkout -b rel-3.0.0
Set the `cachet_ver` build argument to `v3.0.0`
git commit -am "Cachet v3.0.0 release"
git tag -a v3.0.0 -m "Cachet Release v3.0.0"
git push origin v3.0.0
```

Then to finish the process:

* Add [Release on GitHub](https://github.com/CachetHQ/Docker/releases)
* Add automated build for the new tag on [Docker Hub](https://hub.docker.com/r/cachethq/docker/builds/)

Periodically back-port changes from the most recent minor version branch to `main`.

## Multiple releases

Sometimes we get a little behind the upstream Cachet project, and need to make a few releases at once. 

```
gsed s/v3.0.0/v3.0.1/g -i Dockerfile
git commit -am "Cachet v3.0.1 release"
git tag -a v3.0.1 -m "Cachet Release v3.0.1"
git push origin v3.0.1
```

Then setup releases on GitHub.
