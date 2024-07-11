# Tenderduty Setup Script

This repository contains a bash script to set up and configure Tenderduty, a monitoring tool for blockchain validators. The script will prompt for necessary parameters, create a `config.yml` file, and start the Docker container with the generated configuration.

## Repository URL

[https://github.com/blockpane](https://github.com/blockpane/tenderduty)

## Prerequisites

- Docker
- Bash

## Setup Instructions

1. Clone the repository:

    ```sh
    git clone https://github.com/web3validator/tenderduty_setup_script.git
    cd tenderduty_setup_script
    ```

2. Make the script executable:

    ```sh
    chmod +x setup_tenderduty.sh
    ```

3. Run the script:

    ```sh
    ./setup_tenderduty.sh
    ```

4. Follow the prompts to enter the configuration parameters.

## Script Parameters

The script will prompt for the following parameters:

- Node down alert minutes
- Node down alert severity
- Enable PagerDuty (yes/no)
- PagerDuty API key
- Enable Discord (yes/no)
- Discord webhook URL
- Enable Telegram (yes/no)
- Telegram API key
- Telegram channel ID

For each chain you want to monitor, the script will prompt for:

- Chain name
- Chain ID
- Validator operator address
- Enable stalled alert (yes/no)
- Stalled alert minutes
- Enable consecutive missed alert (yes/no)
- Consecutive missed blocks (default is 5)
- Alert if inactive (yes/no)
- Alert if no servers (yes/no)
- RPC node URL 1
- Alert if RPC node 1 down (yes/no)
- RPC node URL 2 (optional)
- Alert if RPC node 2 down (yes/no)
- RPC node URL 3 (optional)
- Alert if RPC node 3 down (yes/no)

You can add multiple chains by responding `yes` to the prompt asking if you want to add another chain.
