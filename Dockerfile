# Build Elixir piece

FROM elixir:alpine AS elixir-build

RUN apk update --no-cache \
  && apk add --no-cache build-base git openssh

RUN mix local.hex --force \
  && mix local.rebar --force

ENV MIX_ENV=prod

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY config config
RUN mix deps.compile

COPY priv priv
COPY .iex.exs .
COPY lib lib

RUN mix compile

# Build the Javascript stuff

FROM node:lts-alpine AS js-build

WORKDIR /app

ENV NODE_ENV=prod

COPY --from=elixir-build /app/deps deps
WORKDIR /app/assets
COPY assets/package.json assets/yarn.lock ./
RUN yarn install

COPY assets .
RUN yarn run deploy

# Put it all together

FROM elixir-build AS release-build

WORKDIR /app

COPY --from=elixir-build /app .
COPY --from=js-build /app/priv/static ./priv/static

RUN mix phx.digest
RUN mix release

RUN ls -R /app/_build

# Put it into an empty Alpine container

FROM alpine:latest
RUN apk update --no-cache && apk add --no-cache openssl ncurses-libs
ENV LANG=en_US.UTF-8

WORKDIR /app

COPY --from=release-build /app/_build/prod/rel/level10 .

EXPOSE 4000

ENTRYPOINT ["/app/bin/level10"]
CMD ["start"]

