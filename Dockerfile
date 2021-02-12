FROM alpine:3.13

RUN apk add --no-cache jq openjdk11-jre-headless bash findutils

RUN mkdir -p /tmp/versionish/packs/
COPY packs/ /tmp/versionish/packs/
COPY config.json scripts/ /tmp/versionish/

ENTRYPOINT ["/bin/bash"]

