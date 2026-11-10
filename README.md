# exeslim (v36372)

[ryanlewis/exeslim](https://github.com/ryanlewis/exeslim) plus [Ultimate](https://github.com/HazAT/ultimate).

A deployment-target exe.dev image that already has Ultimate installed: Node 26, pnpm, git, nginx, Playwright Chromium, and a systemd unit. nginx on `:8000` is the exe.dev HTTPS proxy target and only lets the VM owner in (`X-ExeDev-Email`).

```sh
ssh exe.dev new --name=v36372-factory --image=v36372/exeslim:<build-id>
```

Take `<build-id>` from [Docker Hub](https://hub.docker.com/r/v36372/exeslim/tags). `:latest` works, but exe.dev caches mutable tags for up to an hour — pin the build id when you just pushed.

## What's in it

Everything in exeslim, then:

| Piece | Where |
|---|---|
| Node 26 + pnpm 11.8 | `/usr/local` |
| Ultimate clone | `/home/exedev/ultimate` (HazAT/ultimate, pinned SHA) |
| Ultimate service | `ultimate.service` → `127.0.0.1:4747` |
| nginx | `:8000` → Ultimate, owner-only |
| Playwright Chromium | `~/.cache/ms-playwright` |

Deliberately still absent: docker, the exeuntu workstation stack.

## Build

```sh
BUILD_ID=$(date -u +%Y-%m-%d).local.1
docker build --platform linux/amd64 \
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

CI on `main` publishes the same tags. Set repo secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`.

## VM

```sh
ssh exe.dev new \
  --name=v36372-factory \
  --image=v36372/exeslim:<build-id> \
  --cpu=2 --memory=4GB --disk=25GB \
  --tag=v36372 \
  --comment='"Ultimate factory (exeslim + HazAT/ultimate)"'
```

The public URL is `https://<name>.exe.xyz` (private to the exe.dev account). Ultimate itself binds loopback; use nginx, or `ssh -L 4747:127.0.0.1:4747 <name>.exe.xyz`.

Point it at a project:

```sh
echo /home/exedev/some-repo > ~/.ultimate/current-project
sudo systemctl restart ultimate
```
