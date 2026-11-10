# exeslim (v36372)

[ryanlewis/exeslim](https://github.com/ryanlewis/exeslim) plus [Ultimate](https://github.com/HazAT/ultimate).

A deployment-target exe.dev image that already has Ultimate installed: Node 26, pnpm, git, nginx, Playwright Chromium, and a systemd unit. nginx on `:8000` is the exe.dev HTTPS proxy target and only lets the VM owner in (`X-ExeDev-Email`). A user extension at `~/.ultimate/extensions/exedev` admits that same identity into Ultimate.

```sh
ssh exe.dev new --name=v36372-factory --image=ghcr.io/v36372/exeslim:<build-id>
```

Take `<build-id>` from [GHCR](https://github.com/v36372/exeslim/pkgs/container/exeslim). Docker Hub (`v36372/exeslim`) is the same image once `DOCKERHUB_TOKEN` is set. Pin the build id — exe.dev caches `:latest` for up to an hour.

## What's in it

Everything in exeslim, then:

| Piece | Where |
|---|---|
| Node 26 + pnpm 11.8 | `/usr/local` |
| Ultimate clone | `/home/exedev/ultimate` (HazAT/ultimate, pinned SHA) |
| Ultimate service | `ultimate.service` → `127.0.0.1:4747` |
| nginx | `:8000` → Ultimate, owner-only |
| exe.dev admit | `~/.ultimate/extensions/exedev` |
| Playwright Chromium | `~/.cache/ms-playwright` |

Deliberately still absent: docker, the exeuntu workstation stack.

## Build

```sh
BUILD_ID=$(date -u +%Y-%m-%d).local.1
docker build --platform linux/amd64 --provenance=false --sbom=false \
  --build-arg BUILD_ID="$BUILD_ID" \
  -t v36372/exeslim:latest \
  -t v36372/exeslim:"$BUILD_ID" \
  .
```

Override the Ultimate pin with `--build-arg ULTIMATE_SHA=<sha>` / `ULTIMATE_REPO=<url>`.

## Push

```sh
docker login
docker push v36372/exeslim:latest
docker push v36372/exeslim:"$BUILD_ID"
```

CI on `main` publishes to `ghcr.io/v36372/exeslim`. Set repo secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` to also push Docker Hub.

## VM

```sh
ssh exe.dev new \
  --name=v36372-factory \
  --image=ghcr.io/v36372/exeslim:<build-id> \
  --cpu=2 --memory=4GB --disk=25GB \
  --tag=v36372 \
  --comment='"Ultimate factory (exeslim + HazAT/ultimate)"'
```

Private GHCR packages need `--registry-auth='USER:TOKEN'`. The public URL is `https://<name>.exe.xyz` (private to the exe.dev account). Ultimate itself binds loopback; use nginx, or `ssh -L 4747:127.0.0.1:4747 <name>.exe.xyz`.

Point it at a project:

```sh
echo /home/exedev/some-repo > ~/.ultimate/current-project
sudo systemctl restart ultimate
```
