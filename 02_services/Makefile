# =============================================================
# homelab サービス起動・停止コマンド
# 使い方: make <コマンド名>
# =============================================================

# .env を make 実行ディレクトリ（/opt/homelab/）から明示的に読み込む
# -f で compose/ を指定するとプロジェクトディレクトリが compose/ になるため
# --env-file で .env の場所を明示する
COMPOSE = docker compose --env-file .env

# compose/ にある yml ファイルをすべて対象にする（削除したサービスは自動的に除外される）
ALL_SERVICES = $(addprefix -f ,$(wildcard compose/*.yml))

# -------------------------------------------------------------
# まとめて起動・停止
# -------------------------------------------------------------

.PHONY: up-all
up-all:
	$(COMPOSE) $(ALL_SERVICES) up -d

.PHONY: snapshot-versions
snapshot-versions:
	$(COMPOSE) $(ALL_SERVICES) images > deployed_images.txt

.PHONY: down
down:
	$(COMPOSE) $(ALL_SERVICES) down

# -------------------------------------------------------------
# 監視ダッシュボード
# -------------------------------------------------------------

.PHONY: up-monitoring
up-monitoring:
	$(COMPOSE) -f compose/monitoring.yml up -d

.PHONY: down-monitoring
down-monitoring:
	$(COMPOSE) -f compose/monitoring.yml down

.PHONY: logs-monitoring
logs-monitoring:
	$(COMPOSE) -f compose/monitoring.yml logs -f

# -------------------------------------------------------------
# Mastodon
# -------------------------------------------------------------

.PHONY: up-mastodon
up-mastodon:
	$(COMPOSE) -f compose/mastodon.yml up -d

.PHONY: down-mastodon
down-mastodon:
	$(COMPOSE) -f compose/mastodon.yml down

.PHONY: logs-mastodon
logs-mastodon:
	$(COMPOSE) -f compose/mastodon.yml logs -f

# -------------------------------------------------------------
# Element（Matrix）
# -------------------------------------------------------------

.PHONY: up-element
up-element:
	$(COMPOSE) -f compose/element.yml up -d

.PHONY: down-element
down-element:
	$(COMPOSE) -f compose/element.yml down

.PHONY: logs-element
logs-element:
	$(COMPOSE) -f compose/element.yml logs -f

# -------------------------------------------------------------
# Discord Bot
# -------------------------------------------------------------

.PHONY: up-discord-bot
up-discord-bot:
	$(COMPOSE) -f compose/discord_bot.yml up -d

.PHONY: down-discord-bot
down-discord-bot:
	$(COMPOSE) -f compose/discord_bot.yml down

.PHONY: logs-discord-bot
logs-discord-bot:
	$(COMPOSE) -f compose/discord_bot.yml logs -f

# -------------------------------------------------------------
# ローカル AI 踏み台
# -------------------------------------------------------------

.PHONY: up-ai-proxy
up-ai-proxy:
	$(COMPOSE) -f compose/ai_proxy.yml up -d

.PHONY: down-ai-proxy
down-ai-proxy:
	$(COMPOSE) -f compose/ai_proxy.yml down

.PHONY: logs-ai-proxy
logs-ai-proxy:
	$(COMPOSE) -f compose/ai_proxy.yml logs -f

# -------------------------------------------------------------
# ゲームサーバ（Factorio）
# -------------------------------------------------------------

.PHONY: up-game-factorio
up-game-factorio:
	$(COMPOSE) -f compose/game_factorio.yml up -d

.PHONY: down-game-factorio
down-game-factorio:
	$(COMPOSE) -f compose/game_factorio.yml down

.PHONY: logs-game-factorio
logs-game-factorio:
	$(COMPOSE) -f compose/game_factorio.yml logs -f

# -------------------------------------------------------------
# ゲームサーバ（Windrose / UE5）
# -------------------------------------------------------------

.PHONY: up-game-windrose
up-game-windrose:
	$(COMPOSE) -f compose/game_windrose.yml up -d

.PHONY: down-game-windrose
down-game-windrose:
	$(COMPOSE) -f compose/game_windrose.yml down

.PHONY: logs-game-windrose
logs-game-windrose:
	$(COMPOSE) -f compose/game_windrose.yml logs -f
