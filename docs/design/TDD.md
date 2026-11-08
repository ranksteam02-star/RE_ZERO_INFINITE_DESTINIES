# Technical Design Document — Prototype v0.3

## ขอบเขตที่สร้างจริง

ลำดับข้อมูล: JSON → StoryManager → DialogueUI → user input → StoryManager → ChoiceSystem → GameState → signals → UI; SaveManager อ่าน/คืน snapshot ของ GameState และสั่ง StoryManager แสดงตำแหน่งที่โหลด

| Module | ไฟล์ | ความรับผิดชอบ |
|---|---|---|
| GameState | `scripts/autoload/game_state.gd` | ข้อมูลกลาง, getters, mutation signals, deep snapshots, new game reset |
| StoryManager | `scripts/managers/story_manager.gd` | validate graph, progress, conditions, duplicate-selection guard |
| ChoiceSystem | `scripts/systems/choice_system.gd` | validate effects, whitelist dispatch, record choice |
| DialogueUI | `scripts/systems/dialogue_ui.gd` | presentation, typewriter, choice buttons, keyboard |
| SaveManager | `scripts/managers/save_manager.gd` | JSON, validation, temp write, prior-version backup, restore |
| Main | `scripts/managers/main.gd` | signal wiring, toolbar, new game confirmation, fullscreen |

RelationshipSystem ยังไม่ได้แยก manager; การปรับค่าความสัมพันธ์อยู่ใน GameState ตาม baseline ไม่มี TimelineManager/BattleManager/UIManager เต็มรูปแบบ ห้ามสร้าง singleton ทั้งหมดก่อนมีการใช้งานจริง

## สถานะและขอบเขตค่า

Player: hp/max_hp, stamina, mental_stability, courage, knowledge, combat_ability. HP อยู่ใน 0..max_hp; max_hp >=1; stamina และ mental_stability อยู่ใน 0..100. Courage/knowledge/combat_ability ยังไม่มี balance cap โดย GameState; validator ของ effect/save จำกัดตัวเลขจำนวนเต็มให้อยู่ใน ±1,000,000

Relationships มี trust, affection, suspicion, fear, resentment อยู่ใน -100..100. API baseline เพิ่ม character ID ใหม่ได้. World state ใช้ค่าเริ่มต้นจากสเปก แต่ยังไม่มี world simulation

Story state: chapter_id/current_node/current_timeline. Flags เป็น bool; choice_history เก็บ ID ตามลำดับ. timeline_data/persistent_memory เป็น Dictionary ว่างสำหรับอนาคต ไม่ใช่ระบบย้อนเวลา

## Signals

- `GameState.state_changed(category, key, value)` — ทุก mutation และ restore แจ้งผู้ฟัง
- `StoryManager.line_requested(line)` — UI แสดงข้อมูลสำเนา
- `StoryManager.choices_requested(node_id, choices, prompt)` — UI สร้างปุ่ม
- `StoryManager.dialogue_finished()` / `story_error(message)`
- `DialogueUI.continue_requested()` / `choice_selected(node_id, choice_id)`
- `SaveManager.save_notification(message)`

StoryManager ไม่รู้ path ภายใน UI. UI ไม่แก้ GameState และไม่เลือก next_node เอง Main เป็นจุดประกอบระบบ จึงไม่มีวงจรอ้างอิงระหว่าง manager

## Story execution

ตรวจ graph ทั้งก้อนก่อนเปลี่ยน story ที่เล่นอยู่: types, required strings, effect schema, duplicate choice IDs, asset types, next destinations. ไม่มี execute/eval จาก JSON

Condition nodes ถูก resolve ก่อนนำเสนอ มี visited guard หยุดวงวนพร้อมข้อความอ่านได้. Dialogue cycles อาจใช้เล่าเรื่องวนได้ในอนาคต; campaign ที่ส่งมอบไม่มี cycle. เส้นทางทั้งหมดถูกทดสอบแยกอีกชั้น

Choice ต้องส่ง expected node ID. ถ้าไม่ใช่ node ปัจจุบัน, ไม่อยู่ใน choice state หรือ busy จะปฏิเสธ ปุ่มถูกปิดทันทีที่กด และ graph ปัจจุบันไม่มีการย้อนเข้า choice เดิมโดยอัตโนมัติ. การเริ่มใหม่/โหลดก่อนเลือกอนุญาตให้เลือกใหม่ได้ตามปกติ

## Thai typewriter

RichTextLabel เก็บข้อความเต็ม ใช้ `TextServer.VC_GLYPHS_AUTO` กับ visible_ratio เพื่อ reveal หลัง shaping ไม่ตัด byte string. ใช้ `_process` แทน timer/coroutine ที่อาจวิ่งข้าม scene; `_exit_tree` หยุด process. ฟอนต์ Sarabun รองรับไทยและ Latin ในไฟล์เดียว ถูก bundle พร้อม OFL license. เปิด MSDF ใน font import เพื่อหลีกเลี่ยง Rect2i glyph-bounds error ที่พบใน raster path ของเครื่องทดสอบ

## Save v1

```json
{
  "save_version": 1,
  "completed": false,
  "state": {
    "player_stats": {}, "relationships": {}, "world_state": {},
    "story_state": {}, "story_flags": {}, "choice_history": [],
    "timeline_data": {}, "persistent_memory": {}
  }
}
```

ตัวอย่างนี้อธิบาย envelope ไม่ใช่ Save ที่โหลดได้จริง เพราะ story_state ต้องมี chapter_id/current_node ที่มีอยู่ใน graph

- อ่านไม่เกิน 1 MiB; parse และ validate ทุกอย่างก่อนแก้ live state
- Missing optional categories/fields เติมจาก initial snapshot; story chapter/node เป็น mandatory
- ปฏิเสธ unknown save_version, numeric type ผิด, fractional number, HP/relationship เกินขอบเขต, missing node, chapter mismatch และ completed ที่ไม่ใช่ terminal dialogue
- เขียน `.tmp` → flush/close → ย้าย primary ที่ valid เป็น `.bak` → rename tmp เป็น primary
- ไม่หมุน primary ที่ corrupt มาทับ known-good backup; ถ้า final rename ล้มเหลวพยายามคืน backup
- โหลด primary ไม่ได้จึงลอง `.bak`; ทั้งคู่ไม่ได้จะไม่เปลี่ยน GameState
- สถานะ completed ถูกเก็บแยกจาก current_node เพื่อโหลดข้อความสุดท้ายโดยไม่ replay choice effects
- ไม่อ้างว่า power-loss durability สมบูรณ์ทุก filesystem; เป็นกลยุทธ์ลดการสูญหายใน prototype
- ยังไม่มี legacy version ที่ปล่อยจริง จึง reject เวอร์ชันอื่นแทนการเดารูปแบบ. เพิ่ม migration dispatcher ใน validate_payload เมื่อมี v2 พร้อม fixtures จาก v1

## New Game กับ Timeline

`reset_new_game()` ล้างทั้งเกมตาม initial snapshot โดยตั้งใจ ใช้เฉพาะเมื่อผู้เล่นยืนยันเริ่มใหม่ การย้อนเวลาในอนาคตต้องมี restore policy แยก persistent/resettable ก่อนเขียน TimelineManager ห้าม reuse reset_new_game เป็น death-return

## การขยาย

เพิ่มเรื่องด้วยข้อมูลตาม AUTHORING_TH. ก่อนเพิ่ม node type ใหม่ต้องเพิ่ม validator, executor, presentation signal และ tests. อย่าเพิ่ม field ที่มีผลกับ save โดยไม่กำหนด defaults/migration. โครง 3D เป็น scaffold พร้อม Orthographic Camera เท่านั้น ยังไม่มี movement/controller/collision
