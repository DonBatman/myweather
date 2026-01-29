# MyWeather

A high-performance, immersive weather engine for Luanti that adds dynamic atmosphere, directional wind physics, and persistent weather states.

## ✨ Features
* **Dynamic Weather Cycle:** Transitions from clear skies to cloudy, rain, storms, or snow.
* **Lightning & Thunder:** Visual "ghost" lightning (no fire!) with directional audio.
* **Wind Physics:** Players are pushed by strong winds; wind vanes point to the strongest current.
* **Weather Station:** A functional node to check temperature, humidity, and a 5-minute forecast.
* **Persistence:** Weather states and timers are saved to the server disk—rain won't stop just because the server restarted.
* **Snow Accumulation:** Snow builds up in layers during storms and melts when the sun comes out.

## ⌨️ Chat Commands
| Command | Description | Privileges |
| :--- | :--- | :--- |
| `/setweather <type>` | Force weather (clear, clouds, rain, storm, hail, etc.) | server |
| `/setwind <knots>` | Manually set the wind speed (0-100) | server |
| `/weather` | Check the current global system and wind speed | none |
| `/strike` | Test a lightning bolt at your current position | server |

## 📦 Crafting
### Weather Station
* [Glass] [Glass] [Glass]
* [Steel] [Copper] [Steel]
* [Wood] [Wood] [Wood]

### Rain Barrel
* [Wood] [Empty] [Wood]
* [Wood] [Empty] [Wood]
* [Wood] [Wood] [Wood]

