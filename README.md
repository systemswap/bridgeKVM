# bridgeKVM

This script sets up a network bridge on a Linux host for use in virtual machines (e.g. KVM guests).

The bridge replaces your host’s direct network interface and allows virtual machines to act like first-class network participants in your LAN (with DHCP, router access, etc.).

---

## 🔧 How to use

To download and run the script, use the following commands:

```bash
cd ~/Downloads

curl -O https://raw.githubusercontent.com/systemswap/bridgeKVM/main/setup-linuxMainBridge.sh

chmod +x setup-linuxMainBridge.sh

./setup-linuxMainBridge.sh
```

---

## 🖥️ During execution

- You will be shown a list of available network interfaces.
- Enter the name of your **physical adapter**, for example:

```
enp14s0
```

- Confirm that it should be replaced by a bridge named `mainBridge`.

---

## ✅ After setup

- Your host will receive its IP via the bridge `mainBridge`.
- Virtual machines can connect to this bridge for full LAN access.

---

## 📝 Notes

- Do **not** use `curl | bash` because the script requires interactive input.
- Works with most modern Linux distributions that use NetworkManager.
