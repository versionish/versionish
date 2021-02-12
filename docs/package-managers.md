# Package Manager Particularities

Some package managers need additional tasks or other additional information.
Those parts are described in this guide.

## Apache Maven Package Manager

The versionish docker image has a working JRE, but no maven installed.
Therefore you *must* provide a maven wrapper in your working copy.
Installation instructions for maven wrapper can be found [here](https://github.com/takari/maven-wrapper).

