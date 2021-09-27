#!/bin/bash

set -x

export SECRET_BASE=$(mix phx.gen.secret)
export MIX_ENV=prod

mix deps.get --only prod
mix compile
mix assets.deploy
mix release
