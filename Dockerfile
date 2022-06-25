###
### Builder Stage
###
FROM elixir:1.13-alpine AS builder

RUN apk update --no-cache \
  && apk add --no-cache build-base openssh git

WORKDIR /app

RUN mix local.hex --force \
  && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY lib lib
RUN mix compile --warnings-as-errors

COPY priv priv
COPY assets assets
RUN mix assets.deploy

COPY config/runtime.exs config/
COPY rel rel
RUN mix release

###
### Final Stage - Separate image to keep it smaller
###
FROM alpine:3.16 AS app
RUN apk update --no-cache \
  && apk add --no-cache libstdc++ openssl ncurses-libs

ENV LANG=en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV ECTO_IPV6 true
ENV ERL_AFLAGS "-proto_dist inet6_tcp"

WORKDIR /app
RUN chown nobody /app

COPY --from=builder --chown=nobody:root /app/_build/prod/rel ./

USER nobody:nobody

RUN set -eux; \
  ln -nfs /app/$(basename *)/bin/$(basename *) /app/entry

CMD /app/entry start
