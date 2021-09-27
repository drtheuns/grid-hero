# Grid Hero

A simple browser-based soft-realtime game where you move around in a grid and attack.

## Development

First run `mix deps.get`.

Tests can be run with `mix test`.

The application can be run in development using `mix phx.server`.

## Deployment & release

Use the `./build_release.sh` script to build a release. 
However, the gigalixir deployment uses the buildpacks to build the release.
See `.buildpacks` and `elixir_buildpack.config`.

Live demo using Gigalixir at:
https://grid-hero.gigalixirapp.com/
