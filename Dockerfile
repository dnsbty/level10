# Build Elixir piece

FROM elixir:1.12-alpine AS elixir-build

RUN apk update --no-cache \
  && apk add --no-cache build-base

WORKDIR /app

RUN mix local.hex --force \
  && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY config/config.exs config/config.exs
COPY config/prod.exs config/prod.exs
RUN mix deps.compile

COPY priv priv
COPY .iex.exs .
COPY lib lib

RUN mix compile --warnings-as-errors

# Build the Javascript stuff

FROM node:lts-alpine AS js-build

WORKDIR /app

ENV NODE_ENV=prod

COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY assets assets
COPY priv priv

# We need the lib folder for Tailwind to be able to purge any unused classes
COPY lib lib

RUN npm run --prefix ./assets deploy

# Put it all together

FROM elixir-build AS release-build

WORKDIR /app
RUN mix esbuild.install

COPY assets assets
COPY --from=js-build /app/assets/node_modules assets/node_modules
COPY --from=js-build /app/priv priv

RUN mix esbuild default --minify

COPY config/runtime.exs config/runtime.exs
RUN mix do phx.digest, release

# Put it into an empty Alpine container

FROM alpine:3.14 AS app
RUN apk update --no-cache && apk add --no-cache libstdc++ openssl ncurses-libs
ENV LANG=en_US.UTF-8

WORKDIR /app

RUN chown nobody:nobody /app
USER nobody:nobody

COPY --from=release-build --chown=nobody:nobody /app/_build/prod/rel/level10 .

ENTRYPOINT ["/app/bin/level10"]
CMD ["start"]

