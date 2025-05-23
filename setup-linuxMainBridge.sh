#!/bin/bash

# 🧾 List available physical Ethernet interfaces
echo "🔌 Available Ethernet interfaces:"
nmcli device status | awk '$2 == "ethernet" {print "  - " $1 " (" $3 ")"}'

# 🎯 Ask which interface should be replaced by a bridge
read -rp $'\nWhich interface should be replaced with the bridge? ' PHYS_IF

# 🔍 Validate interface name
if ! nmcli device status | grep -q "^$PHYS_IF"; then
    echo "❌ Interface '$PHYS_IF' not found."
    exit 1
fi

# ⚠️ Ask for confirmation
read -rp $'\n⚠️  Replace connection '$PHYS_IF' with a bridge? (y/n): ' CONFIRM
[[ "$CONFIRM" != "y" ]] && echo "❌ Cancelled." && exit 0

# 🔥 Remove old bridge and slave if they exist
for NAME in mainBridge mainBridge-slave; do
    if nmcli connection show "$NAME" &>/dev/null; then
        echo "🗑️  Deleting existing connection: $NAME"
        sudo nmcli connection down "$NAME" &>/dev/null
        sudo nmcli connection delete "$NAME"
    fi
done

# ➕ Create new bridge
echo "➕ Creating bridge 'mainBridge'"
sudo nmcli connection add type bridge ifname mainBridge con-name mainBridge

# ➕ Add selected interface as slave
echo "➕ Adding '$PHYS_IF' as slave to 'mainBridge'"
sudo nmcli connection add type ethernet ifname "$PHYS_IF" master mainBridge con-name mainBridge-slave

# 🔁 Enable autoconnect
sudo nmcli connection modify mainBridge connection.autoconnect yes
sudo nmcli connection modify mainBridge-slave connection.autoconnect yes

# ✅ Done
echo -e "\n✅ Bridge 'mainBridge' is now active and replaces '$PHYS_IF'."

# 🖥️ Open the NetworkManager GUI editor
nm-connection-editor &
