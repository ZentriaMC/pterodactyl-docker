# Dockerized Pterodactyl

## Why?

Set up production-ready and more self-contained Pterodactyl instances in no time.

## Do's and don'ts

_WARNING: Opinionated list_

1) Do not set `APP_ENVIRONMENT_ONLY` to `false` - prefer immutability.
2) ...

## FAQ

### How do I get all configurable environment variables for Pterodactyl panel?

Run `rg "env\('[a-zA-Z0-9_]+'(,\s+.+)?\)"` in panel source.
