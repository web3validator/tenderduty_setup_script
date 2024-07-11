#!/bin/bash

# Prompt for configuration parameters
read -p "Node down alert minutes: " node_down_alert_minutes
read -p "Node down alert severity: " node_down_alert_severity
read -p "Enable PagerDuty (yes/no): " pagerduty_enabled
read -p "PagerDuty API key: " pagerduty_api_key
read -p "Enable Discord (yes/no): " discord_enabled
read -p "Discord webhook URL: " discord_webhook
read -p "Enable Telegram (yes/no): " telegram_enabled
read -p "Telegram API key: " telegram_api_key
read -p "Telegram channel ID: " telegram_channel

# Create the configuration directory and file
mkdir -p tenderduty && cd tenderduty
docker run --rm ghcr.io/blockpane/tenderduty:latest -example-config >config.yml

# Generate config.yml with the input parameters
cat > config.yml <<EOL
---

# controls whether the dashboard is enabled.
enable_dashboard: yes
# What TCP port the dashboard will listen on. Only the port is controllable for now.
listen_port: 8888
# hide_logs is useful if the dashboard will be posted publicly. It disables the log feed,
# and obscures most node-related details. Be aware this isn't fully vetted for preventing
# info leaks about node names, etc.
hide_logs: no
# How long to wait before alerting that a node is down.
node_down_alert_minutes: ${node_down_alert_minutes}
# Node Down alert Pagerduty Severity
node_down_alert_severity: ${node_down_alert_severity}

# Should the prometheus exporter be enabled?
prometheus_enabled: yes
# What port should it listen on? For now only port is configurable.
prometheus_listen_port: 28686

# Global setting for pagerduty
pagerduty:
  # Should we use PD? Be aware that if this is set to no it overrides individual chain alerting settings.
  enabled: ${pagerduty_enabled}
  # This is an API key, not oauth token, more details to follow, but check the v1 docs for more info
  api_key: ${pagerduty_api_key}
  # Not currently used, but will be soon. This allows setting escalation priorities etc.
  default_severity: alert

# Discord settings
discord:
  # Alert to discord?
  enabled: ${discord_enabled}
  # The webhook is set by right-clicking on a channel, editing the settings, and configuring a webhook in the integrations section.
  webhook: ${discord_webhook}

# Telegram settings
telegram:
  # Alert via telegram? Note: also supersedes chain-specific settings
  enabled: ${telegram_enabled}
  # API key ... talk to @BotFather
  api_key: ${telegram_api_key}
  # The group ID for the chat where messages will be sent. Google how to find this, will include better info later.
  channel: ${telegram_channel}

# Slack settings
slack:
  # Send alerts to Slack?
  enabled: no
  # The webhook can be added in the Slack app directory.
  webhook: ""
EOL

add_more_chains="yes"
while [ "$add_more_chains" == "yes" ]; do
    read -p "Chain name (e.g., Osmosis): " chain_name
    read -p "Chain ID (e.g., osmosis-1): " chain_id
    read -p "Validator operator address: " valoper_address
    read -p "Enable stalled alert (yes/no): " stalled_enabled
    read -p "Stalled alert minutes: " stalled_minutes
    read -p "Enable consecutive missed alert (yes/no): " consecutive_enabled
    read -p "Consecutive missed blocks (default 5): " consecutive_missed
    read -p "Alert if inactive (yes/no): " alert_if_inactive
    read -p "Alert if no servers (yes/no): " alert_if_no_servers
    read -p "RPC node URL 1: " rpc_node_url_1
    read -p "Alert if RPC node 1 down (yes/no): " rpc_alert_if_down_1
    read -p "RPC node URL 2 (optional): " rpc_node_url_2
    read -p "Alert if RPC node 2 down (yes/no): " rpc_alert_if_down_2
    read -p "RPC node URL 3 (optional): " rpc_node_url_3
    read -p "Alert if RPC node 3 down (yes/no): " rpc_alert_if_down_3

    cat >> config.yml <<EOL

  "${chain_name}":
    chain_id: ${chain_id}
    valoper_address: ${valoper_address}
    public_fallback: no

    alerts:
      stalled_enabled: ${stalled_enabled}
      stalled_minutes: ${stalled_minutes}
      consecutive_enabled: ${consecutive_enabled}
      consecutive_missed: ${consecutive_missed:-5}
      consecutive_priority: critical
      alert_if_inactive: ${alert_if_inactive}
      alert_if_no_servers: ${alert_if_no_servers}

      pagerduty:
        enabled: ${pagerduty_enabled}
        api_key: ""

      discord:
        enabled: ${discord_enabled}
        webhook: ""

      telegram:
        enabled: ${telegram_enabled}
        api_key: ""
        channel: ""

      slack:
          enabled: no
          webhook: ""

    nodes:
      - url: ${rpc_node_url_1}
        alert_if_down: ${rpc_alert_if_down_1}
EOL

    if [[ -n "$rpc_node_url_2" ]]; then
      cat >> config.yml <<EOL
      - url: ${rpc_node_url_2}
        alert_if_down: ${rpc_alert_if_down_2}
EOL
    fi

    if [[ -n "$rpc_node_url_3" ]]; then
      cat >> config.yml <<EOL
      - url: ${rpc_node_url_3}
        alert_if_down: ${rpc_alert_if_down_3}
EOL
    fi

    read -p "Do you want to add another chain? (yes/no): " add_more_chains
done

# Start the Docker container
docker run -d --name tenderduty -p "8888:8888" -p "28686:28686" --restart unless-stopped -v $(pwd)/config.yml:/var/lib/tenderduty/config.yml ghcr.io/blockpane/tenderduty:latest

# Display the logs
docker logs -f --tail 20 tenderduty
