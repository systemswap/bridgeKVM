#!/bin/bash

PHYS_IF="enp14s0"
BRIDGE_NAME="mainBridge"
SLAVE_NAME="mainBridge-slave"
ETH_CONN_NAME="enp14s0-autoconnect"

# 🧾 Zeige aktuellen Status
echo "📡 Verfügbare Netzwerkgeräte:"
nmcli device status | awk '$2 == "ethernet" {print "  - " $1 " (" $3 ")"}'

# ❓ Fragemodus
read -rp $'\n🔀 Was möchtest du tun?\n1) Bridge aktivieren\n2) Bridge deaktivieren\n> ' MODE

if [[ "$MODE" == "1" ]]; then
    echo "⚙️  Aktiviere Bridge-Modus..."

    # Entferne alte Verbindungen (falls vorhanden)
    for NAME in "$BRIDGE_NAME" "$SLAVE_NAME" "$ETH_CONN_NAME"; do
        if nmcli connection show "$NAME" &>/dev/null; then
            echo "🗑️  Entferne alte Verbindung: $NAME"
            sudo nmcli connection down "$NAME" &>/dev/null
            sudo nmcli connection delete "$NAME"
        fi
    done

    # Erstelle neue Bridge
    echo "➕ Erstelle Bridge '$BRIDGE_NAME'"
    sudo nmcli connection add type bridge ifname "$BRIDGE_NAME" con-name "$BRIDGE_NAME"

    # Füge physisches Interface als Slave hinzu
    echo "➕ Füge '$PHYS_IF' als Slave hinzu"
    sudo nmcli connection add type ethernet ifname "$PHYS_IF" master "$BRIDGE_NAME" con-name "$SLAVE_NAME"

    # Autoconnect aktivieren
    sudo nmcli connection modify "$BRIDGE_NAME" connection.autoconnect yes
    sudo nmcli connection modify "$SLAVE_NAME" connection.autoconnect yes

    # Aktiviere Bridge
    sudo nmcli connection up "$BRIDGE_NAME"

    echo -e "\n✅ Bridge-Modus ist jetzt aktiv."

elif [[ "$MODE" == "2" ]]; then
    echo "🔧 Deaktiviere Bridge-Modus..."

    # Entferne Bridge und Slave
    for NAME in "$BRIDGE_NAME" "$SLAVE_NAME"; do
        if nmcli connection show "$NAME" &>/dev/null; then
            echo "🗑️  Entferne Verbindung: $NAME"
            sudo nmcli connection down "$NAME" &>/dev/null
            sudo nmcli connection delete "$NAME"
        fi
    done

    # Neue Verbindung für enp14s0 anlegen
    echo "🔌 Erstelle neue Verbindung für '$PHYS_IF'"
    sudo nmcli connection add type ethernet ifname "$PHYS_IF" con-name "$ETH_CONN_NAME"

    # Aktiviere sie
    sudo nmcli connection up "$ETH_CONN_NAME"

    echo -e "\n✅ Einzel-Ethernet-Modus ist jetzt aktiv."

else
    echo "❌ Ungültige Eingabe. Abbruch."
    exit 1
fi
