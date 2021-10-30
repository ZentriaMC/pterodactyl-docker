# Dockerized Pterodactyl

Shoo, go away. There are already [official](https://github.com/pterodactyl/wings/blob/develop/docker-compose.example.yml) [solutions](https://github.com/pterodactyl/panel/blob/develop/docker-compose.example.yml) around.

## Why?

Set up production-ready and more self-contained Pterodactyl instances in no time.

This setup utilizes dind (Docker-in-Docker) to keep servers more self contained.

## Do's and don'ts

_WARNING: Opinionated list_

1) Do not set `APP_ENVIRONMENT_ONLY` to `false` - prefer immutability.
2) ...

## TODOs

- [ ] \(Wings) Set up rootless dind instead of rootful

## FAQ

### How do I get all configurable environment variables for Pterodactyl panel?

Run `rg "env\('[a-zA-Z0-9_]+'(,\s+.+)?\)"` in panel source.
