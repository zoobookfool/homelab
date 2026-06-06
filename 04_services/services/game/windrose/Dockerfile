# Windrose Dedicated Server (Wine on Linux)
#
# Windrose の専用サーバは Windows バイナリのみのため、Wine で動かす
# App ID: 4129620
#
# ※ anonymous ログインで取得できない場合はビルド時に渡す:
#   docker compose ... build --build-arg STEAM_USER=xxx --build-arg STEAM_PASS=xxx

FROM cm2network/steamcmd:latest AS downloader

USER steam

ARG STEAM_USER=anonymous
ARG STEAM_PASS=

# Windrose Dedicated Server をダウンロード
RUN /home/steam/steamcmd/steamcmd.sh \
    +force_install_dir /home/steam/windrose \
    +login ${STEAM_USER} ${STEAM_PASS} \
    +app_update 4129620 validate \
    +quit

# --- Wine ステージ ---
# Ubuntu 22.04 の Wine 6.x は UE5 非対応のため WineHQ から Wine 9+ を導入
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV WINEDEBUG=-all
ENV WINEPREFIX=/root/.wine

# WineHQ リポジトリから Wine 9+ をインストール
# ※ & をこの RUN に混ぜると apt-get install がバックグラウンドになり Wine が
#   インストールされないまま RUN が終了するため、別 RUN に分割する
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        gnupg \
        ca-certificates \
        xvfb \
    && wget -qO /etc/apt/keyrings/winehq.key https://dl.winehq.org/wine-builds/winehq.key \
    && echo "deb [arch=amd64,i386 signed-by=/etc/apt/keyrings/winehq.key] https://dl.winehq.org/wine-builds/ubuntu/ jammy main" \
       > /etc/apt/sources.list.d/winehq.list \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-stable \
    && rm -rf /var/lib/apt/lists/*

# Wine prefix を事前初期化（Mono/Gecko のダウンロードをスキップ）
# 別 RUN にすることで & が上の apt-get install チェーンに干渉しない
RUN Xvfb :99 -screen 0 800x600x8 & \
    XVFB_PID=$! && \
    sleep 2 && \
    DISPLAY=:99 WINEDLLOVERRIDES="mscoree,mshtml=" wineboot --init && \
    wineserver -w && \
    kill $XVFB_PID 2>/dev/null; true

# SteamCMD でダウンロードしたサーバファイルをコピー
COPY --from=downloader /home/steam/windrose /server

WORKDIR /server

# セーブデータ・設定ファイル（R5/Saved/SaveProfiles/Default/ 以下に保存される）
VOLUME ["/server/R5/Saved"]

# ゲームポート（UDP）
EXPOSE 7777/udp

# Xvfb（仮想ディスプレイ）: Wine の Windows サブシステムが display を要求するため必要
# ランチャー（WindroseServer.exe）ではなくシッピングバイナリを直接実行する
# -nullrhi: UE5 レンダリングなし（専用サーバ用）
# -log: コンソールにログ出力
# XDG_RUNTIME_DIR: wineserver が要求するランタイムディレクトリ
CMD ["bash", "-c", "mkdir -p /tmp/runtime && chmod 700 /tmp/runtime && XDG_RUNTIME_DIR=/tmp/runtime Xvfb :1 -screen 0 800x600x16 & sleep 2 && DISPLAY=:1 XDG_RUNTIME_DIR=/tmp/runtime WINEDLLOVERRIDES='mscoree,mshtml=' wine R5/Binaries/Win64/WindroseServer-Win64-Shipping.exe -Port=7777 -log -nullrhi"]
