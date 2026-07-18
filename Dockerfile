FROM ghcr.io/linuxserver/baseimage-selkies:arch

ARG BUILD_DATE
ARG VERSION=local

LABEL build_version="Local LM Studio version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

ENV TITLE="LM Studio" \
    PIXELFLUX_WAYLAND=true \
    NO_GAMEPAD=true

RUN \
  echo "**** add icon ****" && \
  curl -o \
    /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/lmstudio-logo.png && \
  echo "**** install runtime packages ****" && \
  pacman -Sy --noconfirm --needed \
    kde-cli-tools \
    konsole \
    kwin-x11 \
    plasma-desktop \
    plasma-x11-session \
    rsync && \
  echo "**** install lm studio ****" && \
  cd /tmp && \
  mkdir /opt/lm-studio && \
  curl -o \
    /tmp/lm.app -L \
    "https://lmstudio.ai/download/latest/linux/x64?format=AppImage" && \
  chmod +x /tmp/lm.app && \
  ./lm.app --appimage-extract && \
  mv squashfs-root/* /opt/lm-studio/ && \
  curl -fsSL https://lmstudio.ai/install.sh | HOME=/opt/lm-studio bash && \
  chmod -R o+rX /opt/lm-studio && \
  cp \
    /opt/lm-studio/usr/share/icons/hicolor/0x0/apps/lm-studio.png \
    /usr/share/icons/hicolor/512x512/apps/lm-studio.png && \
  sed -i \
    's#^Exec=.*#Exec=/usr/bin/lm-studio#g' \
    /opt/lm-studio/lm-studio.desktop && \
  cp \
    /opt/lm-studio/lm-studio.desktop \
    /usr/share/applications/ && \
  echo "**** application tweaks ****" && \
  setcap -r \
    /usr/sbin/kwin_wayland && \
  echo "**** cleanup ****" && \
  rm -rf \
    /config/.cache \
    /config/.config \
    /tmp/* \
    /var/cache/pacman/pkg/* \
    /var/lib/pacman/sync/*

RUN \
  printf '%s\n' \
    '#!/bin/bash' \
    '' \
    'cd /opt/lm-studio' \
    'exec ./lm-studio --no-sandbox "$@"' \
    > /usr/bin/lm-studio && \
  printf '%s\n' \
    '#!/bin/bash' \
    '' \
    'if [ ! -f "$HOME/.lmstudio-home-pointer" ]; then' \
    '  printf "%s" "$HOME/.lmstudio" > "$HOME/.lmstudio-home-pointer"' \
    'fi' \
    '' \
    'if [ ! -f "$HOME/.lmstudio/.internal/llmster-install-location.json" ]; then' \
    '  mkdir -p "$HOME/.lmstudio/.internal"' \
    '  rsync -av --ignore-existing /opt/lm-studio/.lmstudio/* "$HOME/.lmstudio/"' \
    '  cp /opt/lm-studio/.lmstudio/.internal/llmster-install-location.json "$HOME/.lmstudio/.internal/llmster-install-location.json"' \
    '  sed -i "s:/opt/lm-studio:$HOME:g" "$HOME/.lmstudio/.internal/llmster-install-location.json"' \
    'fi' \
    '' \
    'exec "$HOME/.lmstudio/bin/lms" "$@"' \
    > /usr/bin/lms && \
  chmod +x \
    /usr/bin/lm-studio \
    /usr/bin/lms

EXPOSE 3000

VOLUME /config
