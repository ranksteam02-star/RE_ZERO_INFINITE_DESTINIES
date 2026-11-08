# Visual Edition 0.4 — สิ่งที่เปลี่ยนและการตรวจสอบ

## ผลลัพธ์

เพิ่ม Windows/Linux standalone packages, ภาพใหม่, title menu, setting persistence, original music และลานเมืองที่เดินคุยได้ โดยคง campaign เดิมและ Save schema v1

## ไฟล์และหน้าที่

- `scenes/main/Game.tscn` / `scripts/managers/game_shell.gd`: entry point, menu, settings, pause/resume, story/world switching, music lifetime
- `scripts/systems/town_world.gd`: สร้างฉาก 3D, collision, player CharacterBody3D, Sprite3D billboard, camera และ NPC interaction
- `Main.tscn` / `main.gd`: story screen เดิม เพิ่ม signals กลับ town/menu
- `dialogue_ui.gd`: portrait atlas, top shade และ layout ใหม่; hidden screen ไม่รับ continue input
- `assets/art/`: key art, transparent character atlas, AtlasTexture resources
- `assets/music/twilight.ogg`: original synthesized bell/pad arrangement 32 วินาที วนซ้ำ
- `export_presets.cfg`: Windows/Linux x86-64, embed PCK, include JSON, exclude tests/docs

## ข้อมูลและความเข้ากันได้

ไม่มีการเปลี่ยน choice IDs, node IDs, effect numbers, story flags หรือ Save version. Campaign JSON เปลี่ยนเฉพาะ visual paths. Save เดิมของ campaign the_thirteenth_bell จึงโหลดได้ตาม schema เดิม

Settings แยกไว้ `user://settings.cfg` มี volume, text speed, text size พร้อม clamp/type checks. Save ยังใช้ `user://save_01.json` และ `.bak`. การเดินในลานไม่มี quest state และไม่ถูก persist ข้าม launch. เมื่อกลับจาก town ไป story ใน session เดียวกัน จะใช้ Main instance เดิม จึงไม่ reset ตำแหน่งเรื่อง

## Input และการหยุดเกม

GameShell ปิด world.active เมื่อเข้าเรื่อง/เมนู. Story Main ถูกตั้ง process_mode DISABLED และซ่อน CanvasLayer เมื่อเปิดเมนู. Settings ปิดปุ่มเมนูด้านล่างและย้าย keyboard focus ไป slider; เมื่อปิดจะคืน disabled states. Window-close และ Quit หยุด stream ก่อนออก

WASD ใช้ physical keys. ตัวละครเดินบนพื้นและถูก StaticBody3D กันออกจากคลอง/สิ่งปลูกสร้าง/ขอบฉาก. E ใช้ระยะห่าง 2.4 units; ปุ่มอ่านเนื้อเรื่องช่วยข้าม exploration ได้

## ภาพและประสิทธิภาพ

ฉากเมืองเป็น stylized low-poly diorama ที่สร้างด้วยโค้ด ไม่ใช่ฉากเดียวกับภาพวาดหน้าบทสนทนา. ตัวละครใช้ AtlasTexture จากภาพเดียว และ MSDF font รองรับไทย/Latin. เมืองมีแสง ambient/directional/lantern พร้อม mote animation. Native release เลือก Compatibility เพื่อไม่ต้องพึ่ง Vulkan; renderer ใน Editor ยังคง Forward+ ตาม baseline

## Validation

- Core regression: 43 checks, 0 failures
- Visual Edition integration: 19 checks, 0 failures
- Campaign: 4,096 routes, 4 endings, all 164 visible nodes, 0 failures
- Cross-process save persistence: ผ่าน
- ตรวจ screenshot title, town, dialogue, choice และ settings ที่ 1280×720
- Windows x86-64 export สำเร็จ; Linux x86-64 export สำเร็จและเปิด standalone ได้
- ทดสอบ native Linux exported package ด้วย mouse/keyboard ผ่าน X11 และตรวจ Save ที่เขียนจริง
- Headless exported Linux smoke test ไม่มี ERROR

ข้อจำกัดการยืนยัน: ยังไม่ได้รัน executable บน Windows จริง จึงยังไม่อ้าง Windows hardware QA. Virtual X11 มี V-Sync warning ซึ่งไม่ทำให้เกมหยุด. การตรวจภาพไม่ใช่การ benchmark บน GPU ของผู้เล่น

## ข้อจำกัดที่ยังอยู่

ไม่มี battle/timeline/inventory, ไม่มี autosave/หลายช่อง, ไม่มี world quest progression, sprite ยังไม่มี animation frames, เรื่องใช้ภาพฉากหลังหลักเดียว. Native build ไม่มี installation program; แตก ZIP แล้วเปิด executable. ไม่มี code signing

## วิธี rollback

กลับไป tag v0.3.0-prototype เพื่อใช้รุ่นก่อนภาพใหม่. Save schema ไม่เปลี่ยน แต่ควรสำรอง user data ก่อนเปลี่ยนรุ่น. การเปลี่ยน settings ไม่แก้ player state
