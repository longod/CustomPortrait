# Custom Portrait
So tired of looking at the rendered character image?

This mod allows you to replace the character image in the inventory with your favorite portrait image. Morrowind is a role-playing game.

## Requirements
- Morrowind
- The latest nightly build of Morrowind Script Extender 2.1

## Installation
./Data Files/MWSE/mods/longod/CustomPortrait

## Features
- Display the portrait in inventory instead of the rendered character image.
- Global settings and individual settings for each character.
- Any aspect ratio can be specified.
- Width can be cropped.
- Can be previewed in config.
- Click on the armor rating at the bottom of the portrait to toggle to the rendered character image.
- Includes one portrait of Nerevarine. Change to your favorite portrait.

## Image File Requirements
- It must be placed under **Data files** or its subdirectories.
  - Alternatively, you may overwrite the default file (MWSE\mods\longod\CustomPortrait\portrait.dds).
- Image file format must be DDS, TGA or BMP.
- It must have power-of-2 dimensions (i.e. 64, 128, 256, 512, 1024).
  - If the aspect ratio does not match that of the image before resizing, shrink or stretch the image, or add margins. It can be adjusted in the config.
- The aspect ratio of the image is recommended **1:2** or close to it. This is because that is the aspect ratio of the original character image.
  - If the image is too wide, the usability of the inventory will be impaired. Also, if the image is too tall, the bottom portion of the image will be cropped.

## Recommend mod
- [UI Expansion](https://www.nexusmods.com/morrowind/mods/46071)
  - It allows you to copy and paste text, making it easier to select path.

## Known Issues or TODO
- Width-based scaling
  - Currently the mod uses Height-based scaling, very tall images will be cropped at the bottom. This is because the item list is on the right side of the inventory and it would be useful to be able to adjust the width of the portrait with a crop.
- Offset position 
  - Currently it is based on the top left corner, but it might be useful to be able to adjust it. However, the processing of the original character image is affected.
- Equip, unequip, tooltips and item use events are sometimes incorrect when going to and from mod config.

[GitHub](https://github.com/longod/CustomPortrait)