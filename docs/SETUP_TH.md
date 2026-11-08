> เอกสารพื้นฐานรุ่น 0.3 — สถานะล่าสุดและการเปลี่ยน entry point ดู [Visual Edition 0.4](VISUAL_EDITION_04.md)

# คู่มือเปิดโปรเจกต์และตั้งค่า Godot

## A. เป้าหมาย

เปิดเกมภาษาไทยที่อ่านบทสนทนา เลือกเส้นทาง และบันทึก/โหลดได้ทันที ไม่ต้องคัดลอกสคริปต์ทีละไฟล์ โปรเจกต์ตั้ง Autoload, Theme, Main Scene และ signal connections ไว้แล้ว

## B. เวอร์ชันและการเปิด

ใช้ Godot **4.6.3 stable Standard** ซึ่งเป็นเวอร์ชันที่ทดสอบจริง ไม่รับรอง Godot 3 หรือ Godot 4 รุ่นอื่นโดยยังไม่รันทดสอบ

1. แตก ZIP ลงโฟลเดอร์ที่เขียนได้ อย่าเปิดไฟล์จากภายใน ZIP
2. Project Manager → Import → เลือก `project.godot` → Import & Edit
3. รอ FileSystem import เสร็จ (ฟอนต์ MSDF อาจใช้เวลาสักครู่ในการสร้าง glyph ครั้งแรก) ตรวจ Output ว่าไม่มีข้อความ Parse Error
4. กด F5 เพื่อรันทั้งโปรเจกต์; F6 ใช้รัน Scene ปัจจุบัน ซึ่งอาจไม่ใช่ Main
5. กด F8 เพื่อหยุดเกมจาก Editor

## C. ไฟล์และ Node Tree

```text
Main (Node)                      scripts/managers/main.gd
├── World (Node3D)
│   ├── Camera3D                  Orthogonal, Size 12
│   ├── DirectionalLight3D
│   └── WorldEnvironment
├── SaveManager (Node)            scripts/managers/save_manager.gd
├── StoryManager (Node)           scripts/managers/story_manager.gd
└── UI (CanvasLayer)
    ├── HUD (Control, Full Rect)  assets/theme.tres
    │   ├── DialogueUI           scenes/dialogue/DialogueUI.tscn
    │   │   ├── Background
    │   │   └── Margin/Layout
    │   │       ├── CharacterPortrait
    │   │       └── DialoguePanel/Padding/Content
    │   │           ├── CharacterName
    │   │           ├── DialogueText
    │   │           ├── ContinueIndicator
    │   │           └── ChoiceContainer
    │   └── Top/Rows
    │       ├── Title / Subtitle / StatusLabel
    │       ├── Tools (New Game / Save / Load / Speed)
    │       └── ErrorLabel (ข้อความสถานะ)
    └── NewGameConfirmation
```

ปุ่ม debug เดิมยังมีใน Scene แต่ซ่อนไว้ ปุ่มนี้ตั้งใจให้กดผลซ้ำเพื่อทดสอบ GameState จึงไม่ควรเปิดให้ผู้เล่นใช้ระหว่างอ่านเรื่อง

## D. Inspector และ Project Settings

| รายการ | ค่า |
|---|---|
| Main Scene | `res://scenes/main/Main.tscn` |
| Globals → Autoload | `GameState` → `res://scripts/autoload/game_state.gd`, Enabled |
| Viewport | 1920 × 1080 |
| Window Override | 1280 × 720 |
| Stretch Mode | `canvas_items` |
| Renderer เริ่มต้น | Forward+ |
| Main → Story Path | `res://data/stories/the_thirteenth_bell.json` |
| DialogueUI → Characters Per Second | 35 |
| Camera3D → Projection | Orthogonal |

ทุกสคริปต์ attach ให้แล้ว หากสร้างใหม่ ให้เลือก Node ตาม Tree → Attach Script → เลือกไฟล์ข้างต้น ไม่ต้องเพิ่ม signal ใน Inspector ซ้ำ เพราะ `_ready()` เชื่อมไว้ในโค้ด

ถ้าจะเล่นฉากสั้น: เลือก Main → Inspector → Story Path เป็น `res://data/stories/chapter_01.json` แล้ว F5 เมื่อเสร็จเปลี่ยนกลับก่อนส่ง build เนื้อเรื่องทั้งสองใช้ chapter ID ต่างกัน Save ของฉากหนึ่งจะไม่ถูกโหลดลงอีกฉาก

## E. โค้ดฉบับเต็ม

โค้ดพร้อมใช้งานอยู่ใน `scripts/` แยกตามหน้าที่ ไม่มีขั้นตอนที่ต้องเติม pseudocode อ่านบทบาทและ API ได้ใน TDD โครงสร้าง `.tscn` เป็นไฟล์ข้อความ แก้ผ่าน Editor ได้ตามปกติ

## F. ตรวจด้วยมือ

- เริ่มเกม → เห็นตอนที่ 01 และข้อความภาษาไทย
- กด Space ระหว่างพิมพ์ → ข้อความเต็ม; กดซ้ำ → หน้าถัดไป
- ที่ตัวเลือกแรก กดบันทึก → เลือกช่วย → HP 90, Trust 10
- กดโหลด → กลับก่อนเลือก HP 100 และเลือกอีกแขนงได้
- ปิดเกม เปิดใหม่ → โหลด → ได้สถานะที่บันทึกไว้
- ปุ่มเริ่มเกมใหม่มีหน้าต่างยืนยัน; ยกเลิกแล้วสถานะต้องไม่เปลี่ยน
- ลอง F11, 1280×720, 1920×1080, เมาส์ และ Tab/Enter

## G. Save อยู่ที่ไหน

ใช้ Godot `user://` เปิดได้จาก Editor → Project → Open User Data Folder บน Windows มักอยู่ใต้ `%APPDATA%/Godot/app_userdata/` ตามชื่อโปรเจกต์ ให้ใช้เมนูของ Editor เพื่อหลีกเลี่ยงการเดา path

ไฟล์หลัก `save_01.json`, backup `save_01.json.bak`, ไฟล์ระหว่างเขียน `save_01.json.tmp` ไม่ควรลบ backup หากยังไม่ได้ตรวจว่าไฟล์หลักใช้ได้

## H. แก้ปัญหา

- **Identifier GameState not declared:** เปิดผ่าน `project.godot` และตรวจ Globals/Autoload ห้ามเปลี่ยนชื่อเป็น Game_State
- **Node not found:** ตรวจชื่อและตำแหน่ง Node เทียบ Tree อย่าเปลี่ยน path โดยไม่แก้ `@onready`
- **อักษรเป็นสัญลักษณ์:** ใช้ `assets/theme.tres` ที่มี Sarabun พร้อม MSDF import ห้ามลบฟอนต์ที่ bundle มา
- **Vulkan เปิดไม่ได้:** ใช้ Compatibility ตาม README ไม่ต้องแก้ระบบเนื้อเรื่อง
- **เปิดเรื่องแล้วมีข้อความแจ้งผิดพลาด:** ตรวจ JSON, next_node และ asset paths ดู AUTHORING_TH
- **Save โหลดไม่ได้:** ตรวจว่าเป็น chapter เดียวกันและ save_version 1 ระบบจะลอง backup และคงสถานะปัจจุบันถ้าทั้งสองใช้ไม่ได้
- **ข้อความยาว:** เลื่อนในกรอบบทสนทนาได้ เปลี่ยนหน้าแล้วเลื่อนกลับด้านบนอัตโนมัติ
- **ทดสอบค้าง:** อ่าน Output หา Parse Error ก่อน ผลเก่าจะใช้ยืนยันการแก้ล่าสุดไม่ได้

## I. Windows Export (ยังไม่ได้รันทดสอบจริง)

1. Editor → Manage Export Templates → ติดตั้ง template **4.6.3** ให้ตรงกับ Editor
2. Project → Export → Add → Windows Desktop
3. ใช้ x86_64, main scene ตามโปรเจกต์
4. Resources → include `*.json` เพื่อให้ไฟล์เนื้อเรื่องถูกบรรจุ และ exclude `docs/*,tests/*`
5. Export ไปโฟลเดอร์นอก source เช่น `build/windows/InfiniteDestinies.exe`
6. ทดสอบบน Windows ที่ไม่มี Godot ติดตั้ง โดยคัดลอกไฟล์ประกอบทั้งหมดไปด้วย
7. ตรวจทั้งเริ่มใหม่, โหลดข้ามการเปิดโปรแกรม, ไทย/อังกฤษ, ขนาดหน้าต่าง และ renderer ก่อนเรียกว่า Windows release
