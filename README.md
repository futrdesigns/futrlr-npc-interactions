# Lunar New Year Themed NPC Interaction Script

This resource adds dynamic NPC interactions themed around the Lunar New Year. NPCs can remember players, hold grudges, give red envelope rewards, react to player reputation, and shopkeepers can call police if repeatedly robbed. The script supports ESX, QBCore (both versions), and standalone environments. It includes configurable notification and dispatch wrappers compatible with ox, okok, mythic, qb, esx, CodeSign (cd_dispatch, ccd_dispatch, 3D), qb-dispatch, and custom systems.

---

## Features

- Dynamic NPC memory per player
- Reputation system with positive and negative outcomes
- Grudge system with expiration and scaling hostility
- Red envelope reward system with weighted loot
- Shopkeeper robbery detection with police dispatch
- Configurable notification and dispatch wrappers
- ESX, QBCore, and Standalone compatibility

---

## Requirements

Optional but recommended:
- ox_lib for improved notifications (if selected)
- Your preferred notification resource (okokNotify, mythic_notify, etc.)
- Your preferred dispatch resource (cd_dispatch, CodeSign 3D Dispatch, qb-dispatch)

---

## Installation

1. Download the resource folder and name it `lunar_npc`.
2. Place the folder inside your server’s `resources` directory.
   ```
   resources/lunar_npc
   ```

3. Add the resource to your server configuration file (`server.cfg`):
   ```
   ensure lunar_npc
   ```

4. Open `config.lua` and configure the following options:
   - Notification system:
     ```
     Config.NotificationSystem = "ox"
     ```
     Options: ox, okok, mythic, qb, esx, custom.

   - Dispatch system:
     ```
     Config.DispatchSystem = "codesign3d"
     ```
     Options: codesign, codesign3d, cd_dispatch, ccd_dispatch, qb, custom.

5. (Optional) Adjust NPC locations, models, and scenarios in the `Config.NPCs` table inside `config.lua`.

6. (Optional) Set up shops, framework-specific inventory, or job systems depending on your server's framework.

---

## Updating

To update the script:
1. Replace the existing `client.lua`, `server.lua`, and `config.lua` with the latest versions.
2. Review new configuration fields for changes or additions.
3. Restart your server or use the command:
   ```
   refresh
   restart lunar_npc
   ```

---

## Support

If you need assistance with framework integration, dispatch notifications, custom shops, or additional features, the support discord will be out soon
