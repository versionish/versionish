# We use npm for dependency management
FROM node:14-alpine3.12 as dependencies-solver

RUN apk add --no-cache git

COPY package*.json /bats/

WORKDIR /bats

RUN npm install


# Minimalistic image
FROM versionish/versionish:1.0.0

LABEL Maintainer="Andreas Felder <ajdergute@gmail.com>"

ENV BATS_HELPERS_DIR=/opt/bats-helpers
ARG TEST_DIR
ENV TEST_DIR=/tests

# Bats
COPY --from=dependencies-solver /bats/node_modules/bats /opt/bats

# ztombol's bats helpers
COPY --from=dependencies-solver /bats/node_modules/bats-support /opt/bats-helpers/bats-support
COPY --from=dependencies-solver /bats/node_modules/bats-file /opt/bats-helpers/bats-file
COPY --from=dependencies-solver /bats/node_modules/bats-assert /opt/bats-helpers/bats-assert
COPY --from=dependencies-solver /bats/node_modules/bats-mock /opt/bats-helpers/bats-mock

RUN apk add --no-cache coreutils ncurses
RUN ln -s /opt/bats/bin/bats /sbin/bats

WORKDIR ${TEST_DIR}

ENTRYPOINT ["/sbin/bats"]
CMD ["-v"]
