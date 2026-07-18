# docker-lm-studio

Minimal LM Studio container image based on `ghcr.io/linuxserver/baseimage-selkies:arch`.

This fork keeps the LinuxServer.io Selkies desktop runtime and LM Studio overlay, but removes unrelated developer tooling. The container starts LM Studio's API server automatically and exposes the GUI through Selkies.

## Features

- LM Studio GUI over Selkies on port `3000`.
- OpenAI-compatible API server on port `1234`.
- Embedded s6 custom service for `lms server start --bind 0.0.0.0`.
- Optional runtime catalog update on startup with `LMS_UPDATE`.
- CPU, NVIDIA, AMD, and Intel compose profiles.
- GHCR image build/publish tasks.
- Build-time package groups controlled by Docker build args.

## Ports

The default compose file binds ports to localhost only:

```yaml
127.0.0.1:1234:1234/tcp
127.0.0.1:3000:3000/tcp
```

- `3000` - LM Studio GUI through Selkies.
- `1234` - LM Studio API server.

## Volumes

```yaml
./config:/config
```

All persistent LM Studio, KDE, and runtime state lives under `./config`. This path is ignored by git and Docker build context.

## Run

CPU/default:

```bash
task up:cpu
```

NVIDIA:

```bash
task up:nvidia
```

AMD:

```bash
task up:amd
```

Intel:

```bash
task up:intel
```

The hardware-specific tasks use these compose overrides:

- `docker-compose.nvidia.yaml` - `gpus: all` and NVIDIA env vars.
- `docker-compose.amd.yaml` - `/dev/dri` and `/dev/kfd`.
- `docker-compose.intel.yaml` - `/dev/dri`.

## Build

Build the image:

```bash
task build
```

Build and push `latest`:

```bash
task push
```

Publish a version tag and `latest`:

```bash
LM_STUDIO_VERSION=1.2.3 task image:publish
```

Create a GitHub release:

```bash
LM_STUDIO_VERSION=1.2.3 task release:create
```

The image name is hardcoded in compose:

```text
ghcr.io/psauxwwf/docker-lm-studio:latest
```

## Build Args

The Dockerfile splits pacman packages into build-time groups.

Required packages are always installed:

```bash
gtk3
kde-cli-tools
plasma-desktop
rsync
```

LM Studio runtime packages are optional and disabled by default:

```bash
cuda
vulkan-headers
```

Enable them with:

```bash
INSTALL_LMSTUDIO_RUNTIME_PACKAGES=true task build
```

Optional helper packages are enabled by default:

```bash
python
wl-clipboard
```

Disable them with:

```bash
INSTALL_OPTIONAL_HELPER_PACKAGES=false task build
```

X11 fallback packages are disabled by default:

```bash
kwin-x11
plasma-x11-session
```

Enable them with:

```bash
INSTALL_X11_FALLBACK_PACKAGES=true task build
```

Current compose defaults:

```yaml
INSTALL_LMSTUDIO_RUNTIME_PACKAGES: ${INSTALL_LMSTUDIO_RUNTIME_PACKAGES:-false}
INSTALL_OPTIONAL_HELPER_PACKAGES: ${INSTALL_OPTIONAL_HELPER_PACKAGES:-true}
INSTALL_X11_FALLBACK_PACKAGES: ${INSTALL_X11_FALLBACK_PACKAGES:-false}
```

## Runtime Updates

The image embeds `root/custom-services.d/lms-server`, which starts the API server and can update installed LM Studio runtimes after the server becomes ready.

Default:

```yaml
LMS_UPDATE=${LMS_UPDATE-true}
```

Disable runtime update on startup:

```bash
LMS_UPDATE=false task up:cpu
```

The update step runs:

```bash
lms runtime get --list --allow-incompatible
lms runtime update --all --yes --allow-incompatible
```

## Auto-Evict

LM Studio can keep multiple models loaded, but JIT-loaded models are affected by Auto-Evict. When Auto-Evict is enabled, switching models through API clients can unload the previously JIT-loaded model.

The current setting is stored in:

```text
config/.lmstudio/settings.json
```

The relevant key is:

```json
"unloadPreviousJITModelOnLoad": false
```

The stable way to change this is through LM Studio GUI:

```text
Developer -> Server Settings -> Auto-Evict
```

## Notes

- `cuda` is not installed by default. NVIDIA driver libraries should be provided by NVIDIA Container Toolkit, while LM Studio manages its own inference runtime packs.
- `vulkan-headers` is not installed by default because it is a header package, not a runtime dependency.
- The manual desktop shortcut for starting LMS was removed. The API server is started by the embedded s6 service instead.
- X11 fallback is disabled by default. Enable `INSTALL_X11_FALLBACK_PACKAGES=true` only if you need the baseimage fallback path.
