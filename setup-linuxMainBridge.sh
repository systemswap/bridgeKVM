#!/bin/bash

# Zeige verfügbare Ethernet-Geräte
echo "Verfügbare Ethernet-Schnittstellen:"
nmcli device status | awk '$2 == "ethernet" { print "  - " $1 " (" $3 ")" }'

# Benutzer wählt ein Interface
read -rp "Welche Schnittstelle soll durch die Bridge ersetzt werden? " PHYS_IF

# Prüfe ob Interface existiert
if ! nmcli device status | grep -q "^$PHYS_IF"; then
    echo "❌ Schnittstelle '$PHYS_IF' wurde nicht gefunden."
    exit 1
fi

# Bestätigung
echo "⚠️  Achtung: $PHYS_IF wird aus dem Netzwerk genommen und durch 'mainBridge' ersetzt."
read -rp "Fortfahren? (ja/nein): " CONFIRM

if [[ "$CONFIRM" != "ja" ]]; then
    echo "❌ Abgebrochen."
    exit 0
fi

# Alte Verbindung deaktivieren und löschen (falls vorhanden)
sudo nmcli connection down "$PHYS_IF" 2>/dev/null
sudo nmcli connection delete "$PHYS_IF" 2>/dev/null

# Neue Bridge anlegen
sudo nmcli connection add type bridge ifname mainBridge con-name mainBridge
sudo nmcli connection modify mainBridge ipv4.method auto
sudo nmcli connection modify mainBridge ipv6.method ignore

# Physikalische Schnittstelle als Slave hinzufügen
sudo nmcli connection add type ethernet ifname "$PHYS_IF" con-name mainBridge-slave master mainBridge

# Verbindungen aktivieren
sudo nmcli connection up mainBridge-slave
sudo nmcli connection up mainBridge

# DHCP optional anstoßen
sudo dhclient mainBridge

# Autoconnect aktivieren
sudo nmcli connection modify mainBridge connection.autoconnect yes
sudo nmcli connection modify mainBridge-slave connection.autoconnect yes

echo "✅ Bridge 'mainBridge' wurde eingerichtet und ersetzt '$PHYS_IF'."

# grafischen Netzwerk-Editor zur Überprüfung
nm-connection-editor &
