#!/bin/bash

BRIDGE_NAME="mainBridge"
ETH_CONN_NAME_SUFFIX="-autoconnect"

# 🛠 Ask for bridge mode
read -rp $'\n🔧 What would you like to do?\n1) Activate bridge mode\n2) Deactivate bridge mode\n> ' MODE

if [[ "$MODE" == "1" ]]; then
    echo "🔍 Scanning for available Ethernet interfaces..."

    # Get all Ethernet devices with their state
    mapfile -t ETH_DEVICES < <(nmcli -t -f DEVICE,STATE,TYPE device | awk -F: '$3 == "ethernet" {print $1 ":" $2}')

    if [[ ${#ETH_DEVICES[@]} -eq 0 ]]; then
        echo "❌ No Ethernet interfaces found. Exiting."
        exit 1
    fi

    # Show list
    echo -e "\n📡 Available Ethernet interfaces:"
    for i in "${!ETH_DEVICES[@]}"; do
        DEVICE=$(cut -d: -f1 <<< "${ETH_DEVICES[$i]}")
        STATE=$(cut -d: -f2 <<< "${ETH_DEVICES[$i]}")
        STATUS=""
        [[ "$STATE" == "connected" ]] && STATUS="(active)"
        echo "  $((i+1))) $DEVICE $STATUS"
    done

    # Prompt for selection
    read -rp $'\n➡️  Select the interface to use as bridge slave (number): ' IFACE_INDEX
    ((IFACE_INDEX--))

    SELECTED_ENTRY="${ETH_DEVICES[$IFACE_INDEX]}"
    if [[ -z "$SELECTED_ENTRY" ]]; then
        echo "❌ Invalid selection. Exiting."
        exit 1
    fi

    PHYS_IF=$(cut -d: -f1 <<< "$SELECTED_ENTRY")
    SLAVE_NAME="${PHYS_IF}-slave"
    ETH_CONN_NAME="${PHYS_IF}${ETH_CONN_NAME_SUFFIX}"

    echo "⚙️  Activating bridge mode with interface '$PHYS_IF'..."

    # Remove old connections if present
    for NAME in "$BRIDGE_NAME" "$SLAVE_NAME" "$ETH_CONN_NAME"; do
        if nmcli connection show "$NAME" &>/dev/null; then
            echo "🗑️  Removing old connection: $NAME"
            sudo nmcli connection down "$NAME" &>/dev/null
            sudo nmcli connection delete "$NAME"
        fi
    done

    # Create bridge
    echo "➕ Creating bridge '$BRIDGE_NAME'"
    sudo nmcli connection add type bridge ifname "$BRIDGE_NAME" con-name "$BRIDGE_NAME"

    # Add physical interface as bridge slave
    echo "➕ Adding '$PHYS_IF' as bridge slave"
    sudo nmcli connection add type ethernet ifname "$PHYS_IF" master "$BRIDGE_NAME" con-name "$SLAVE_NAME"

    # Enable autoconnect
    sudo nmcli connection modify "$BRIDGE_NAME" connection.autoconnect yes
    sudo nmcli connection modify "$SLAVE_NAME" connection.autoconnect yes

    # Bring up the bridge
    sudo nmcli connection up "$BRIDGE_NAME"

    echo -e "\n✅ Bridge mode is now active."

elif [[ "$MODE" == "2" ]]; then
    echo "🔧 Deactivating bridge mode..."

    # Try to clean up any existing bridge and slave
    if nmcli connection show "$BRIDGE_NAME" &>/dev/null; then
        echo "🗑️  Removing bridge: $BRIDGE_NAME"
        sudo nmcli connection down "$BRIDGE_NAME" &>/dev/null
        sudo nmcli connection delete "$BRIDGE_NAME"
    fi

    # Remove all associated slave connections
    SLAVE_CONNS=$(nmcli -t -f NAME,TYPE connection show | awk -F: '$2 == "ethernet" && $1 ~ /-slave$/ {print $1}')
    for SLAVE in $SLAVE_CONNS; do
        echo "🗑️  Removing slave connection: $SLAVE"
        sudo nmcli connection down "$SLAVE" &>/dev/null
        sudo nmcli connection delete "$SLAVE"
    done

    # Prompt to create new standard Ethernet connection
    echo -e "\n📝 You can now manually create a standard Ethernet connection if needed."

    echo -e "\n✅ Bridge mode is now deactivated."

else
    echo "❌ Invalid input. Exiting."
    exit 1
fi

# 🖥️ Open NetworkManager GUI at the end
echo -e "\n🖥️ Launching NetworkManager GUI..."
nm-connection-editor &
