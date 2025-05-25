#!/bin/bash

# 🔍 Verfügbare Ethernet-Geräte sammeln (unabhängig vom Status)
mapfile -t ETH_DEVICES < <(nmcli -t -f DEVICE,TYPE device | awk -F: '$2 == "ethernet" {print $1}')

if [[ ${#ETH_DEVICES[@]} -eq 0 ]]; then
    echo "❌ Keine Ethernet-Geräte gefunden. Abbruch."
    exit 1
fi

# 🧾 Liste anzeigen
echo "📡 Verfügbare Ethernet-Geräte:"
for i in "${!ETH_DEVICES[@]}"; do
    echo "  $((i+1))) ${ETH_DEVICES[$i]}"
done

# ❓ Auswahl
read -rp $'\n🔀 Bitte wähle ein Interface (Zahl): ' IFACE_INDEX
((IFACE_INDEX--))

if [[ -z "${ETH_DEVICES[$IFACE_INDEX]}" ]]; then
    echo "❌ Ungültige Auswahl. Abbruch."
    exit 1
fi

PHYS_IF="${ETH_DEVICES[$IFACE_INDEX]}"
BRIDGE_NAME="mainBridge"
SLAVE_NAME="${PHYS_IF}-slave"
ETH_CONN_NAME="${PHYS_IF}-autoconnect"

# ❓ Moduswahl
read -rp $'\n⚙️  Was möchtest du tun?\n1) Bridge aktivieren\n2) Bridge deaktivieren\n> ' MODE

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

    # Bridge erstellen
    echo "➕ Erstelle Bridge '$BRIDGE_NAME'"
    sudo nmcli connection add type bridge ifname "$BRIDGE_NAME" con-name "$BRIDGE_NAME"

    # Slave hinzufügen
    echo "➕ Füge '$PHYS_IF' als Slave hinzu"
    sudo nmcli connection add type ethernet ifname "$PHYS_IF" master "$BRIDGE_NAME" con-name "$SLAVE_NAME"

    # Autoconnect aktivieren
    sudo nmcli connection modify "$BRIDGE_NAME" connection.autoconnect yes
    sudo nmcli connection modify "$SLAVE_NAME" connection.autoconnect yes

    # Bridge aktivieren
    sudo nmcli connection up "$BRIDGE_NAME"

    echo -e "\n✅ Bridge-Modus ist jetzt aktiv."

elif [[ "$MODE" == "2" ]]; then
    echo "🔧 Deaktiviere Bridge-Modus..."

    # Bridge und Slave entfernen
    for NAME in "$BRIDGE_NAME" "$SLAVE_NAME"; do
        if nmcli connection show "$NAME" &>/dev/null; then
            echo "🗑️  Entferne Verbindung: $NAME"
            sudo nmcli connection down "$NAME" &>/dev/null
            sudo nmcli connection delete "$NAME"
        fi
    done

    # Neue Einzelverbindung erstellen
    echo "🔌 Erstelle neue Verbindung für '$PHYS_IF'"
    sudo nmcli connection add type ethernet ifname "$PHYS_IF" con-name "$ETH_CONN_NAME"
    sudo nmcli connection up "$ETH_CONN_NAME"

    echo -e "\n✅ Einzel-Ethernet-Modus ist jetzt aktiv."

else
    echo "❌ Ungültige Eingabe. Abbruch."
    exit 1
fi

# 🖥️ NetworkManager GUI öffnen
echo -e "\n🖥️ Starte NetworkManager GUI..."
nm-connection-editor &
