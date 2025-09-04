# [Qbox]  Wild Chicken Capturing



**Add an immersive hunting activity to your server with this wild chicken capturing script, fully integrated with the OX ecosystem (ox_lib, ox_target, ox_inventory).**



---

## 📜 What is it?

`babo_chickencap` is a **lightweight** and **high-performance** script that populates areas of your map with wild chickens. Players can track them, bait them with food, and then attempt to capture them. It's the perfect addition for servers that use a chicken coop system or are looking to add **immersive** and **economic activities**.

---
![image|690x493, 50%](upload://ap1QT4KmV2WNfh5engtJwEMjfiU.jpeg)
![image|690x466, 50%](upload://xykM6tRCHvEDYXkFCXpXZ9szyOV.jpeg)
![image|690x453, 50%](upload://q2EI9IYQY3K0nhWvj4dswg93PME.jpeg)


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

* **ox_target**

---

## ⚙️ Easy Installation

1. **Install** all dependencies.

2. **Add** the `hen`, `rooster`, and `chicken_feed` items to your `ox_inventory` configuration.

3. **Drag and drop** `babo_chickencap` into your `resources` folder.

4. **Add** `ensure babo_chickencap` to your `server.cfg`.

5. **You're all set!**




