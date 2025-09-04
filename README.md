# [Qbox]  Wild Chicken Capturing



**Add an immersive hunting activity to your server with this wild chicken capturing script, fully integrated with the OX ecosystem (ox_lib, ox_target, ox_inventory).**



---

## 📜 What is it?

`babo_chickencap` is a **lightweight** and **high-performance** script that populates areas of your map with wild chickens. Players can track them, bait them with food, and then attempt to capture them. It's the perfect addition for servers that use a chicken coop system or are looking to add **immersive** and **economic activities**.

<img width="1256" height="898" alt="image" src="https://github.com/user-attachments/assets/2e2355dd-4b6c-4deb-bda3-1ad01f5c161c" />
<img width="1274" height="861" alt="image" src="https://github.com/user-attachments/assets/6dc97820-f226-4f95-8cb0-a2b085569c75" />
<img width="1245" height="818" alt="image" src="https://github.com/user-attachments/assets/a46e96e3-c591-4f96-86e2-5e6d558e7c8a" />




## ✨ Key Features

* 🐔 **Dynamic & Natural Spawns**: Chickens appear realistically in forest areas that you can **fully configure** (positions, maximum number, etc.).

* 🌾 **Interactive Bait System**: Players must use an item (default `chicken_feed`) to attract and calm a chicken before they can attempt a capture.

* 🖐️ **Capture Mechanic via `ox_target`**: Once baited, the player can try to capture the chicken through an `ox_target` interaction, complete with a **progress bar** and a configurable **failure chance** to spice up the game.

* 📦 **Seamless `ox_inventory` Integration**: A successful capture gives a `hen` or `rooster` item with **metadata ready** for your other scripts (like remaining breeds).

* 🛡️ **Secure Server-Side Logic**: All management of spawns, captures, and items is handled **server-side** to optimize performance and prevent cheating.

* 🔧 **Complete Configuration**: Everything is configurable in a single file: items, timers, success chances, spawn zones, map blips, and even the emotes played.

* 👮 **Admin Commands**: Includes commands for **debugging**, **manual spawning**, and **entity cleanup** for full control.

---

## 📋 Dependencies

* **ox_lib**

* **ox_inventory**

* -- ox_inventory/data/items.lua

-- Food to bait chickens
['chicken_feed'] = {
    label = 'Chicken Feed',
    weight = 500,
    stack = true,
    close = true,
    description = 'A few seeds to attract the poultry.'
},

-- The hen once captured
['hen'] = {
    label = 'Hen',
    weight = 2000,
    stack = false,
    close = true,
    description = 'A live hen. She seems to be in good health.'
},

-- The rooster once captured
['rooster'] = {
    label = 'Rooster',
    weight = 2500,
    stack = false,
    close = true,
    description = 'A live rooster. He looks rather proud.'
},

* **ox_target**

---

## ⚙️ Easy Installation

1. **Install** all dependencies.

2. **Add** the `hen`, `rooster`, and `chicken_feed` items to your `ox_inventory` configuration.

3. **Drag and drop** `babo_chickencap` into your `resources` folder.

4. **Add** `ensure babo_chickencap` to your `server.cfg`.

5. **You're all set!**

* **Discord (Support)**: [Join our Discord](https://discord.gg/PuW242z4mW)


