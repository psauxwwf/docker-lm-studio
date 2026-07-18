FROM ghcr.io/linuxserver/baseimage-selkies:arch

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG INSTALL_LMSTUDIO_RUNTIME_PACKAGES=false
ARG INSTALL_OPTIONAL_HELPER_PACKAGES=true
ARG INSTALL_X11_FALLBACK_PACKAGES=true

# title
ENV TITLE="LM Studio" \
    PIXELFLUX_WAYLAND=true \
    NO_GAMEPAD=true

RUN \
  echo "**** add icon ****" && \
  curl -o \
    /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/lmstudio-logo.png

RUN \
  echo "**** install packages ****" && \
  required_packages=( \
    gtk3 \
    kde-cli-tools \
    plasma-desktop \
    rsync \
  ) && \
  lmstudio_runtime_packages=( \
    cuda \
    vulkan-headers \
  ) && \
  optional_helper_packages=( \
    python \
    wl-clipboard \
  ) && \
  x11_fallback_packages=( \
    kwin-x11 \
    plasma-x11-session \
  ) && \
  packages=("${required_packages[@]}") && \
  if [[ "${INSTALL_LMSTUDIO_RUNTIME_PACKAGES,,}" == "true" ]]; then \
    packages+=("${lmstudio_runtime_packages[@]}"); \
  fi && \
  if [[ "${INSTALL_OPTIONAL_HELPER_PACKAGES,,}" == "true" ]]; then \
    packages+=("${optional_helper_packages[@]}"); \
  fi && \
  if [[ "${INSTALL_X11_FALLBACK_PACKAGES,,}" == "true" ]]; then \
    packages+=("${x11_fallback_packages[@]}"); \
  fi && \
  pacman -Sy --noconfirm --needed "${packages[@]}" && \
  rm -rf \
    /var/cache/pacman/pkg/* \
    /var/lib/pacman/sync/*

RUN \
  echo "**** install lm studio appimage ****" && \
  mkdir -p /opt/lm-studio /tmp/lm-studio && \
  curl -o \
    /tmp/lm-studio/lm.app -L \
    "https://lmstudio.ai/download/latest/linux/x64?format=AppImage" && \
  chmod +x /tmp/lm-studio/lm.app && \
  /tmp/lm-studio/lm.app --appimage-extract && \
  mv squashfs-root/* /opt/lm-studio/ && \
  rm -rf \
    /tmp/* \
    squashfs-root

RUN \
  echo "**** install lm studio cli ****" && \
  curl -fsSL https://lmstudio.ai/install.sh | HOME=/opt/lm-studio bash && \
  rm -rf \
    /config/.cache \
    /config/.config

RUN \
  echo "**** configure lm studio ****" && \
  chmod -R o+rX /opt/lm-studio && \
  cp \
    /opt/lm-studio/usr/share/icons/hicolor/0x0/apps/lm-studio.png \
    /usr/share/icons/hicolor/512x512/apps/lm-studio.png && \
  sed -i \
    's#^Exec=.*#Exec=/usr/bin/lm-studio#g' \
    /opt/lm-studio/lm-studio.desktop && \
  cp \
    /opt/lm-studio/lm-studio.desktop \
    /usr/share/applications/

RUN \
  echo "**** application tweaks ****" && \
  setcap -r \
    /usr/sbin/kwin_wayland

# add local files
COPY /root /

# ports and volumes
EXPOSE 3000 1234

VOLUME /config

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"
