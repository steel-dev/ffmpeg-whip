FROM debian:bookworm-slim AS build
ARG FFMPEG_REF=master
RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates git build-essential pkg-config yasm nasm \
  libssl-dev libx264-dev libopus-dev libx11-dev libxext-dev \
  libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev libxcb-shape0-dev \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 --branch "${FFMPEG_REF}" https://git.ffmpeg.org/ffmpeg.git
WORKDIR /src/ffmpeg
RUN ./configure \
  --prefix=/usr/local \
  --disable-debug --disable-doc --disable-ffplay --disable-ffprobe \
  --enable-shared --disable-static \
  --enable-openssl \
  --enable-protocol=http,https,tcp,udp,dtls,file,pipe \
  --enable-muxer=whip \
  --enable-gpl --enable-version3 \
  --enable-libx264 --enable-libopus \
  --enable-encoder=libx264,libopus \
  --enable-parser=h264 \
  --enable-bsf=h264_mp4toannexb \
  --enable-filter=scale,fps,format,aresample \
  --enable-indev=x11grab,xcbgrab \
  && make -j"$(nproc)" && make install
RUN install -D /usr/local/bin/ffmpeg /out/ffmpeg && strip /out/ffmpeg || true