#!/bin/bash

# 🧾 Zeige alle verfügbaren Ethernet-Schnittstellen
echo "🔌 Verfügbare Ethernet-Schnittstellen:"
nmcli device status | awk '$2 == "ethernet" {print "  - " $1 " (" $3 ")"}'

# 🎯 Eingabe der zu ersetzenden Schnittstelle
read -rp $'\nWelche Schnittstelle soll durch die Bridge ersetzt werden? ' PHYS_IF

# 🔍 Prüfen, ob die Schnittstelle existiert
if ! nmcli device status | grep -q "^$PHYS_IF"; then
    echo "❌ Schnittstelle '$PHYS_IF' wurde nicht gefunden."
    exit 1
fi

# ❗ Warnung anzeigen
read -rp $'\n⚠️  Die Verbindung '$PHYS_IF' wird durch eine Bridge ersetzt. Fortfahren? (ja/nein): ' CONFIRM
[[ "$CONFIRM" != "ja" ]] && echo "❌ Abgebrochen." && exit 0

# 🔥 Vorhandene mainBridge-Verbindungen löschen (wenn vorhanden)
for NAME in mainBridge mainBridge-slave; do
    if nmcli connection show "$NAME" &>/dev/null; then
        echo "🗑️  Entferne alte Verbindung: $NAME"
        sudo nmcli connection down "$NAME" &>/dev/null
        sudo nmcli connection delete "$NAME"
    fi
done

# ➕ Bridge anlegen
echo "➕ Erstelle neue Bridge 'mainBridge'"
sudo nmcli connection add type bridge ifname mainBridge con-name mainBridge

# ➕ Physikalisches Interface als Bridge-Slave hinzufügen
echo "➕ Verbinde '$PHYS_IF' als Slave mit 'mainBridge'"
sudo nmcli connection add type ethernet ifname "$PHYS_IF" master mainBridge con-name mainBridge-slave

# 🔁 Autoconnect aktivieren
sudo nmcli connection modify mainBridge connection.autoconnect yes
sudo nmcli connection modify mainBridge-slave connection.autoconnect yes

# ✅ Abschlussmeldung
echo -e "\n✅ Bridge 'mainBridge' wurde eingerichtet und ersetzt '$PHYS_IF'."

# 🖥️ Öffne grafischen Netzwerkeditor zur Kontrolle
nm-connection-editor &
