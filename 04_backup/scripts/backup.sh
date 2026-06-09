#!/bin/bash
# backup.sh
# /opt/homelab/ 以下を tar で固めて /opt/backup/ に保存する
# 使い方: sudo bash backup.sh

set -euo pipefail

# --- 設定 ---
BACKUP_SRC="/opt/homelab"
BACKUP_DEST="/opt/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DEST}/homelab_${TIMESTAMP}.tar.gz"

# TODO: 保持する世代数（現在は無制限）
# KEEP_DAYS=7

# --- バックアップ実行 ---
echo "[$(date)] バックアップ開始: ${BACKUP_FILE}"

mkdir -p "${BACKUP_DEST}"

tar -czf "${BACKUP_FILE}" -C / \
  --exclude="${BACKUP_SRC}/monitoring/prometheus" \
  "$(basename ${BACKUP_SRC})"

echo "[$(date)] バックアップ完了: ${BACKUP_FILE}"
echo "[$(date)] サイズ: $(du -sh ${BACKUP_FILE} | cut -f1)"

# TODO: 古いバックアップの削除（世代管理が決まったら有効化）
# find "${BACKUP_DEST}" -name "homelab_*.tar.gz" -mtime +${KEEP_DAYS} -delete
# echo "[$(date)] ${KEEP_DAYS}日以上前のバックアップを削除しました"
