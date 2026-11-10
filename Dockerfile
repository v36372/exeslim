# exeslim + Ultimate. Platform wiring comes from ryanlewis/exeslim; this
# layer adds the toolchain Ultimate needs and runs it behind nginx :8000.
#
# Pin the immutable build-id, not :latest — exe.dev caches mutable tags.

FROM ghcr.io/ryanlewis/exeslim:2026-11-09.70.1@sha256:fa72846b2166bbf556909c6cbcaef91eafcf93164d2d1270f029778dda6f45a0

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG NODE_VERSION=26.13.0
ARG PNPM_VERSION=11.8.0
ARG ULTIMATE_REPO=https://github.com/HazAT/ultimate.git
ARG ULTIMATE_SHA=8f1472e5382eb596ddb552675c4580a9b7039da1

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
	PNPM_HOME=/home/exedev/.local/share/pnpm \
	PATH=/home/exedev/.local/share/pnpm:/home/exedev/.local/share/pnpm/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin \
	ULTIMATE_NO_OPEN=1

# policy-rc.d is gone in the base image so apt-installed services start at
# runtime. Re-add it for the build only, or nginx's postinst fails here.
RUN printf '#!/bin/sh\nexit 101\n' >/usr/sbin/policy-rc.d \
	&& chmod +x /usr/sbin/policy-rc.d \
	&& apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		git \
		nginx \
		openssh-client \
		python3 \
		build-essential \
		pkg-config \
		unzip \
		xz-utils \
		ripgrep \
		fonts-liberation \
		fonts-dejavu-core \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" \
		-o /tmp/node.tar.gz \
	&& tar -xzf /tmp/node.tar.gz -C /usr/local --strip-components=1 \
	&& rm -f /tmp/node.tar.gz \
	&& corepack enable \
	&& corepack prepare "pnpm@${PNPM_VERSION}" --activate \
	&& node -v \
	&& pnpm -v

RUN printf '\nexport PNPM_HOME="$HOME/.local/share/pnpm"\nexport PATH="/usr/local/bin:$PNPM_HOME:$PATH"\n' \
		>>/home/exedev/.bashrc \
	&& printf '\nexport PNPM_HOME="$HOME/.local/share/pnpm"\nexport PATH="/usr/local/bin:$PNPM_HOME:$PATH"\n' \
		>>/home/exedev/.profile \
	&& mkdir -p /home/exedev/.local/share/pnpm /home/exedev/.cache \
	&& chown -R exedev:exedev /home/exedev/.bashrc /home/exedev/.profile /home/exedev/.local /home/exedev/.cache

# Clone as exedev so the tree is writable by the agent. GitHub allows a
# depth-1 fetch of a commit SHA.
USER exedev
WORKDIR /home/exedev
RUN git init ultimate \
	&& git -C ultimate remote add origin "$ULTIMATE_REPO" \
	&& git -C ultimate fetch --depth 1 origin "$ULTIMATE_SHA" \
	&& git -C ultimate checkout --detach FETCH_HEAD \
	&& git -C ultimate config --global --add safe.directory /home/exedev/ultimate \
	&& cd ultimate \
	&& pnpm install --frozen-lockfile \
	&& pnpm add -g "$PWD" \
	&& node node_modules/playwright-core/cli.js install chromium \
	&& command -v ultimate

USER root
WORKDIR /home/exedev
# Chromium's shared libraries. Leaves policy-rc.d in place until this apt run
# finishes, then drops it so runtime apt-get install can start services.
RUN cd /home/exedev/ultimate \
	&& node node_modules/playwright-core/cli.js install-deps chromium \
	&& rm -f /usr/sbin/policy-rc.d \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY nginx/ultimate.conf /etc/nginx/sites-available/ultimate
COPY systemd/ultimate.service /etc/systemd/system/ultimate.service
COPY scripts/ultimate-start.sh /usr/local/bin/ultimate-start
COPY AGENTS.md /home/exedev/.config/shelley/AGENTS.md

RUN chmod 644 /etc/systemd/system/ultimate.service \
	&& chmod 755 /usr/local/bin/ultimate-start \
	&& rm -f /etc/nginx/sites-enabled/default \
	&& ln -s /etc/nginx/sites-available/ultimate /etc/nginx/sites-enabled/ultimate \
	&& nginx -t \
	&& systemctl enable nginx.service \
	&& systemctl enable ultimate.service \
	&& sudo -u exedev git config --global user.name v36372 \
	&& sudo -u exedev git config --global user.email '7565018+v36372@users.noreply.github.com' \
	&& sudo -u exedev git config --global init.defaultBranch main \
	&& chown exedev:exedev /home/exedev/.config/shelley/AGENTS.md \
	&& test -x /usr/local/bin/node \
	&& test -f /home/exedev/ultimate/bin/ultimate.ts \
	&& : >/etc/machine-id \
	&& ln -sf /etc/machine-id /var/lib/dbus/machine-id

EXPOSE 8000

ARG BUILD_ID=dev
LABEL org.opencontainers.image.title="exeslim" \
	org.opencontainers.image.description="ryanlewis/exeslim plus HazAT/ultimate, nginx on :8000." \
	org.opencontainers.image.source="https://github.com/v36372/exeslim" \
	org.opencontainers.image.url="https://github.com/v36372/exeslim" \
	org.opencontainers.image.licenses="MIT" \
	org.opencontainers.image.base.name="ghcr.io/ryanlewis/exeslim:2026-11-09.70.1" \
	org.opencontainers.image.version="${BUILD_ID}"

WORKDIR /home/exedev
CMD ["/usr/local/bin/init"]
