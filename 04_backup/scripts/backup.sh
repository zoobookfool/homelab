#!/bin/bash
# backup.sh
# /opt/homelab/ 以下と PostgreSQL dump を tar で固めて /opt/backup/ に保存する
# 使い方: sudo bash backup.sh

set -euo pipefail

# --- 設定 ---
BACKUP_SRC="/opt/homelab"
BACKUP_DEST="/opt/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DEST}/homelab_${TIMESTAMP}.tar.gz"
TMP_DIR="$(mktemp -d)"
DB_DUMP_DIR="${TMP_DIR}/db_dumps"

# TODO: 保持する世代数（現在は無制限）
# KEEP_DAYS=7

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

container_running() {
  docker ps --format '{{.Names}}' | grep -qx "$1"
}

# --- バックアップ実行 ---
echo "[$(date)] バックアップ開始: ${BACKUP_FILE}"

mkdir -p "${BACKUP_DEST}"
mkdir -p "${DB_DUMP_DIR}"

TAR_EXCLUDES=(
  "--exclude=$(basename "${BACKUP_SRC}")/monitoring/prometheus"
)

if command -v docker >/dev/null 2>&1; then
  if container_running mastodon-db; then
    echo "[$(date)] Mastodon PostgreSQL dump を作成"
    docker exec mastodon-db pg_dump -U mastodon -d mastodon -Fc > "${DB_DUMP_DIR}/mastodon.dump"
    TAR_EXCLUDES+=("--exclude=$(basename "${BACKUP_SRC}")/mastodon/postgres")
  else
    echo "[$(date)] Mastodon DB コンテナが起動していないため、データディレクトリをそのまま含めます"
  fi

  if container_running synapse-db; then
    echo "[$(date)] Synapse PostgreSQL dump を作成"
    docker exec synapse-db pg_dump -U synapse -d synapse -Fc > "${DB_DUMP_DIR}/synapse.dump"
    TAR_EXCLUDES+=("--exclude=$(basename "${BACKUP_SRC}")/element/postgres")
  else
    echo "[$(date)] Synapse DB コンテナが起動していないため、データディレクトリをそのまま含めます"
  fi
else
  echo "[$(date)] docker コマンドが見つからないため、PostgreSQL dump は作成しません"
fi

# -C で親ディレクトリに移動するため、--exclude も tar 内の相対パスで指定する
tar -czf "${BACKUP_FILE}" \
  "${TAR_EXCLUDES[@]}" \
  -C "$(dirname "${BACKUP_SRC}")" "$(basename "${BACKUP_SRC}")" \
  -C "${TMP_DIR}" db_dumps

echo "[$(date)] バックアップ完了: ${BACKUP_FILE}"
echo "[$(date)] サイズ: $(du -sh "${BACKUP_FILE}" | cut -f1)"

# TODO: 古いバックアップの削除（世代管理が決まったら有効化）
# find "${BACKUP_DEST}" -name "homelab_*.tar.gz" -mtime +${KEEP_DAYS} -delete
# echo "[$(date)] ${KEEP_DAYS}日以上前のバックアップを削除しました"
