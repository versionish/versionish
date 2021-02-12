# versionish

Versionish is a tool which should help to extract version information out various package managers.
This version information could then be used in any build pipeline for tagging, pinning, releasing or any other task which needs a version.


The basic assumption is, that it is possible to find a version number and extract a semantic version out of it.

## Installation

Versionish is meant to be started as docker container within your CI/CD pipeline.

Your working copy must be mounted on `/tmp/app` for the detection process.

Optionally one is able to add a custom *version pack*.
For details see, [Version Packs](#version-packs)

A basic command for running versionish could be:

```bash
docker run --name versionish -v <your-working-copy>:/tmp/app ajdergute/versionish:1.0.0
```

## Usage

TODO

## Testing

Testing is done with [BATS](https://github.com/bats-core/bats-core).

You're encouraged to write own tests for custom version packs.

To run tests in this repository please do as follows:

```bash
docker run --name versionish-tests -it --rm -v <path-to-tests-folder-in-this-repo>:/tests:rw ajdergute/versionish-tests:1.0.0 --formatter pretty --recursive .
```

### BATS Options

BATS is also able to produce JUnit compatible test results.
Please refer to their documentation for details.

### Mounting testfolder r/w

It is recommend to mount folder `tests` with write permissions, as you can see in the example.
This would be used for two things.

* First, a JUnit report from BATS will be placed inside this folder and could then be used outside the container.
* Second, all log output from versionish tests a written to a log file placed inside folder `tests`.

## Version Packs

A *version pack*, like heroku build packs or cloud native buildpacks (CNB), consists of a few scripts.
Versionish executes those scripts in a defined order.
All scripts must be placed inside a `bin`-folder.

Thus, a minimal *version pack* could have the following tree:

```
- bin/
    \_ detect
    \_ extract
    \_ convert
```

Each script either has some output on stdout or returns with an exit code other than `SUCCESS`/`0`.

* `detect` : Evaluates if this version pack is responsible for the given working directory.
* `extract`: Reads the version number from package manager.
* `convert`: Conversion of the number out of `extract` to a valid [semantic version](https://semver.org/spec/v2.0.0.html) number.

Versionish uses the first version pack which claims to be responsible for the working copy.
This is the case if `detect` returns a success return value of `0`.

Before a scripts is executed, versionish ensures that it is done in the current working directory.

### Details on mentioned scripts

The following sections describing input and ouput parameters of each mentioned script.

#### detect

Input: Absolute path of your working copy.

Processing hint: mostly this script performs checks on existence of specific files.

Output: The file name which contains the version number.
E.g. for Maven `pom.xml` with success return value.
In all other cases a meaningful error message with an return value greater than zero must be returned.

#### extract

Input: Absolute path and file name from `detect` is given to this script.

Processing hint: Any task must be performed to extract the version number from given file.
E.g. for Maven the maven-help-plugin is executed.

Output: The found version number as it occurs in the source file.
Any error during processing must be reported and a return value greater than zero returned.

#### convert

Input: Takes the version number from `extract` as input.

Processing hint: The main goal here is to remove anything which is not part of semantic versioning specification.
The second part is to add any pre-release or build metadata information to it.
E.g. for Maven often we cut `-SNAPSHOT`.

Output: A version number conforming semantic versioning 2.0.0 or newer.
Any error during processing must be reported and a return value greater than zero returned.


#### Additional output e.g. for logging purpose

If needed additional ouput on stdout could be made by a script.
The output `value` is taken from the last line by a script call.
E.g. assume the following output of script `detect`:

```
Connecting to raw.githubusercontent.com (185.199.108.133:443)
******
failed to connect to raw.githubusercontent.com

Some other output of this script
1.2.3
```
Then the output value is

```
1.2.3
```

### Custom version pack

Versionish tries to provide version packs for all package managers officially supported by
[Heroku Buildpacks](https://devcenter.heroku.com/articles/buildpacks#officially-supported-buildpacks).
If you're using any other source for version information please provide a `detect`, `extract` and `convert` script as described.
Mount the custom version pack into versionish image at `/tmp/versionish/packs/`.
Create a subfolder for your pack.
It is recommend to prefix this folder with `00_` to ensure it is executed before all other version packs.
E.g. the full path to mount may be: `/tmp/versionish/packs/00_custom_tool`.

## Configuration

Configuration per package manager may be done via `config.json` file.

## Package Manager Particularities

See [Package Manager Guide](docs/package-managers.md)

## Contribute

See [How to contribute](docs/contributing.md)

## License

versionish is released under [Apache-2.0](LICENSE)

