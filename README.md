# agent-infra-container

Nix-based **base image** for agent runtime containers.

This repository provides tools and libraries only. It does not start desktop,
VNC, MCP, or application services. Derived runtime images own process
supervision, network exposure, authentication, and lifecycle policy.

The main consumer is
[`darknightlab/pi-web-container`](https://github.com/darknightlab/pi-web-container),
which starts Xvfb/Fluxbox and its application services with Supervisor.

## Included Cua support

The runtime environment includes
[`cua-driver`](https://github.com/trycua/cua), allowing a derived image with a
running Linux X11 session to expose Cua Driver as an MCP stdio server.

The prebuilt Cua release is packaged by `nix/cua-driver.nix`. The derivation:

- pins the release version and hashes for x86_64 and aarch64 Linux;
- patches the foreign ELF interpreter and RPATH for the Nix store;
- installs both `cua-driver` and its required `cua-cursor-theme` sidecar;
- provides D-Bus and AT-SPI packages and activation files for derived X11
  runtimes that need semantic accessibility trees.

This base image intentionally does not run `cua-driver mcp` or
`cua-driver serve`. A derived image should start `cua-driver mcp` from its agent
MCP configuration so the process inherits that image's `DISPLAY` and session
environment.

## Build

Build the Nix runtime environment:

```bash
cd nix
nix build .#runtimeEnv
```

Build the Docker image from the repository root:

```bash
docker build -t agent-infra-container ./nix
```

Build and inspect Cua Driver independently:

```bash
cd nix
nix build .#cuaDriver
./result/bin/cua-driver --version
./result/bin/cua-driver cursor-theme list --json
```

## Runtime ownership

A derived image is responsible for all of the following:

- starting and supervising Xvfb and the window manager;
- creating any D-Bus/AT-SPI session needed for semantic accessibility tools;
- registering `cua-driver mcp` with its agent;
- applying an appropriate Cua capability/permission policy;
- securing VNC/noVNC or other remote-access endpoints;
- handling health checks, logs, signals, and shutdown.

Do not add service startup commands or network listeners to this base image.
