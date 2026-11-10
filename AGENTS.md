You are running in an exe.dev VM.

https://exe.dev/docs/proxy.md has details about the exe.dev HTTPS proxy.

Only use documented exe.dev features (see https://exe.dev/docs.md). Undocumented local endpoints are internal infrastructure—unstable and unsupported.

## This VM is exeslim + Ultimate

The base is [exeslim](https://github.com/ryanlewis/exeslim): systemd, curl, sudo, the `exedev` user. On top: Node 26, pnpm, git, nginx, ripgrep, build-essential, Playwright Chromium, and [Ultimate](https://github.com/HazAT/ultimate).

**Ultimate** is the coding agent. It is a systemd service (`ultimate.service`) listening on `127.0.0.1:4747`. nginx on `:8000` proxies the exe.dev HTTPS URL to it, and refuses requests that are not from the VM owner.

```
systemctl status ultimate nginx
journalctl -u ultimate -u nginx -e
```

The clone is `/home/exedev/ultimate`. To point Ultimate at a project, write the absolute path to `~/.ultimate/current-project` and `sudo systemctl restart ultimate`.

**Not installed:** docker, Chrome/GTK desktop stack, python venv tooling beyond `python3`, Go, uv. `apt` works.

**Git** is Ubuntu 24.04's (2.43). Ultimate prefers 2.54+ for config-based commit-attribution hooks; older git just ignores those hooks.

**Chromium sandbox is off** (`ULTIMATE_CHROMIUM_SANDBOX=0`) because this is a container-as-VM. Screenshot/browser tools use Playwright's Chromium under `~/.cache/ms-playwright`.

**Services are systemd units.** Start/stop with `systemctl`, logs with `journalctl -u <name>`. journald storage is persistent.
