#!/bin/bash

# Prompt for configuration parameters
read -p "Node down alert minutes: " node_down_alert_minutes
read -p "Enable PagerDuty (yes/no): " pagerduty_enabled
if [ "$pagerduty_enabled" == "yes" ]; then
    read -p "PagerDuty API key: " pagerduty_api_key
fi
read -p "Enable Discord (yes/no): " discord_enabled
if [ "$discord_enabled" == "yes" ]; then
    read -p "Discord webhook URL: " discord_webhook
fi
read -p "Enable Telegram (yes/no): " telegram_enabled
if [ "$telegram_enabled" == "yes" ]; then
    read -p "Telegram API key: " telegram_api_key
    read -p "Telegram channel ID: " telegram_channel
fi

# Create the configuration directory and file
mkdir -p tenderduty && cd tenderduty
docker run --rm ghcr.io/blockpane/tenderduty:latest -example-config > config.yml

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
node_down_alert_severity: critical

# Should the prometheus exporter be enabled?
prometheus_enabled: yes
# What port should it listen on? For now only port is configurable.
prometheus_listen_port: 28686

# Global setting for pagerduty
pagerduty:
  enabled: ${pagerduty_enabled}
  api_key: ${pagerduty_api_key:-""}
  default_severity: alert

# Discord settings
discord:
  enabled: ${discord_enabled}
  webhook: ${discord_webhook:-""}

# Telegram settings
telegram:
  enabled: ${telegram_enabled}
  api_key: ${telegram_api_key:-""}
  channel: ${telegram_channel:-""}

# Slack settings
slack:
  enabled: no
  webhook: ""
EOL

add_more_chains="yes"
while [ "$add_more_chains" == "yes" ]; do
    read -p "Chain name (e.g., Osmosis): " chain_name
    read -p "Chain ID (e.g., osmosis-1): " chain_id
    read -p "Validator operator address: " valoper_address
    read -p "Enable stalled alert (yes/no): " stalled_enabled
    if [ "$stalled_enabled" == "yes" ]; then
        read -p "Stalled alert minutes: " stalled_minutes
    fi
    read -p "Enable consecutive missed alert (yes/no): " consecutive_enabled
    if [ "$consecutive_enabled" == "yes" ]; then
        read -p "Consecutive missed blocks (default 5): " consecutive_missed
    fi
    read -p "Alert if inactive (yes/no): " alert_if_inactive
    read -p "Alert if no servers (yes/no): " alert_if_no_servers
    read -p "RPC node URL 1: " rpc_node_url_1
    read -p "Alert if RPC node 1 down (yes/no): " rpc_alert_if_down_1
    read -p "RPC node URL 2 (optional): " rpc_node_url_2
    if [ -n "$rpc_node_url_2" ]; then
        read -p "Alert if RPC node 2 down (yes/no): " rpc_alert_if_down_2
    fi
    read -p "RPC node URL 3 (optional): " rpc_node_url_3
    if [ -n "$rpc_node_url_3" ]; then
        read -p "Alert if RPC node 3 down (yes/no): " rpc_alert_if_down_3
    fi

    cat >> config.yml <<EOL

  "${chain_name}":
    chain_id: ${chain_id}
    valoper_address: ${valoper_address}
    public_fallback: no

    alerts:
      stalled_enabled: ${stalled_enabled}
      stalled_minutes: ${stalled_minutes:-10}
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

    if [ -n "$rpc_node_url_2" ]; then
      cat >> config.yml <<EOL
      - url: ${rpc_node_url_2}
        alert_if_down: ${rpc_alert_if_down_2}
EOL
    fi

    if [ -n "$rpc_node_url_3" ]; then
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
