# =============================================================
# homelab サービス起動・停止コマンド
# 使い方: make <コマンド名>
# =============================================================

# 常時起動サービス
CORE_SERVICES = \
	-f compose/monitoring.yml \
	-f compose/mastodon.yml \
	-f compose/element.yml \
	-f compose/discord_bot.yml \
	-f compose/ai_proxy.yml

# 全サービス
ALL_SERVICES = \
	$(CORE_SERVICES) \
	-f compose/game_factorio.yml \
	-f compose/game_windrose.yml

# -------------------------------------------------------------
# まとめて起動・停止
# -------------------------------------------------------------

.PHONY: up-core
up-core:
	docker compose $(CORE_SERVICES) up -d

.PHONY: up-all
up-all:
	docker compose $(ALL_SERVICES) up -d

.PHONY: down
down:
	docker compose $(ALL_SERVICES) down

# -------------------------------------------------------------
# 監視ダッシュボード
# -------------------------------------------------------------

.PHONY: up-monitoring
up-monitoring:
	docker compose -f compose/monitoring.yml up -d

.PHONY: down-monitoring
down-monitoring:
	docker compose -f compose/monitoring.yml down

.PHONY: logs-monitoring
logs-monitoring:
	docker compose -f compose/monitoring.yml logs -f

# -------------------------------------------------------------
# Mastodon
# -------------------------------------------------------------

.PHONY: up-mastodon
up-mastodon:
	docker compose -f compose/mastodon.yml up -d

.PHONY: down-mastodon
down-mastodon:
	docker compose -f compose/mastodon.yml down

.PHONY: logs-mastodon
logs-mastodon:
	docker compose -f compose/mastodon.yml logs -f

# -------------------------------------------------------------
# Element（Matrix）
# -------------------------------------------------------------

.PHONY: up-element
up-element:
	docker compose -f compose/element.yml up -d

.PHONY: down-element
down-element:
	docker compose -f compose/element.yml down

.PHONY: logs-element
logs-element:
	docker compose -f compose/element.yml logs -f

# -------------------------------------------------------------
# Discord Bot
# -------------------------------------------------------------

.PHONY: up-discord-bot
up-discord-bot:
	docker compose -f compose/discord_bot.yml up -d

.PHONY: down-discord-bot
down-discord-bot:
	docker compose -f compose/discord_bot.yml down

.PHONY: logs-discord-bot
logs-discord-bot:
	docker compose -f compose/discord_bot.yml logs -f

# -------------------------------------------------------------
# ローカル AI 踏み台
# -------------------------------------------------------------

.PHONY: up-ai-proxy
up-ai-proxy:
	docker compose -f compose/ai_proxy.yml up -d

.PHONY: down-ai-proxy
down-ai-proxy:
	docker compose -f compose/ai_proxy.yml down

.PHONY: logs-ai-proxy
logs-ai-proxy:
	docker compose -f compose/ai_proxy.yml logs -f

# -------------------------------------------------------------
# ゲームサーバ（Factorio）
# -------------------------------------------------------------

.PHONY: up-game-factorio
up-game-factorio:
	docker compose -f compose/game_factorio.yml up -d

.PHONY: down-game-factorio
down-game-factorio:
	docker compose -f compose/game_factorio.yml down

.PHONY: logs-game-factorio
logs-game-factorio:
	docker compose -f compose/game_factorio.yml logs -f

# -------------------------------------------------------------
# ゲームサーバ（Windrose / UE5）
# -------------------------------------------------------------

.PHONY: up-game-windrose
up-game-windrose:
	docker compose -f compose/game_windrose.yml up -d

.PHONY: down-game-windrose
down-game-windrose:
	docker compose -f compose/game_windrose.yml down

.PHONY: logs-game-windrose
logs-game-windrose:
	docker compose -f compose/game_windrose.yml logs -f
