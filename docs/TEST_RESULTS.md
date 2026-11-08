# Test Results — Prototype v0.3

## สภาพแวดล้อมที่รันจริง

Godot 4.6.3.stable.official.7d41c59c4 บน Linux. Logic tests ใช้ headless. Visual capture ใช้ Xvfb + OpenGL Compatibility / Mesa llvmpipe. ไม่ใช่การทดสอบบน Windows หรือ GPU ของ Owner

## ผลระบบหลัก

`tests/TestRunner.tscn`: **43 checks, 0 failures**

| กลุ่ม | Expected | Actual |
|---|---|---|
| Baseline | HP100 / Trust0 / flag false / history0 | ผ่าน |
| Test help | HP90 / Trust10 / flag true / history1 | ผ่าน |
| Bounds | HP ไม่ติดลบ, max_hp >=1, trust -100..100 | ผ่าน |
| Snapshots | แก้ nested snapshot ไม่เปลี่ยนต้นฉบับ | ผ่าน |
| New Game | ค่าเริ่มต้นกลับครบ | ผ่าน |
| Dialogue | reveal → continue เป็นคนละการกด | ผ่าน |
| Thai/Latin | มี glyph สระ/พยัญชนะ/วรรณยุกต์และ Latin | ผ่าน |
| Input | Space ผ่าน viewport input เปลี่ยนหน้าเดียว | ผ่าน |
| Presentation | background/portrait โหลด และล้าง portrait เก่า | ผ่าน |
| Choice | แสดงสองตัวเลือก; Continue ข้าม choice ไม่ได้ | ผ่าน |
| Effects | help/observe ให้ผลและปลายทางต่างกัน | ผ่าน |
| Duplicate | stale node/double selection ไม่รับผลซ้ำ | ผ่าน |
| Save/Load | กลับก่อนเลือก, history คงเดิม, ending ไม่ apply ซ้ำ | ผ่าน |
| Recovery | primary เสียใช้ backup; ทั้งคู่เสียไม่แก้ live state | ผ่าน |
| Validation | เติม optional defaults; reject version/type/node ผิด | ผ่าน |
| Story errors | missing destination/effect/file/data type จัดการได้ | ผ่าน |

การทดสอบปุ่มบางส่วนเรียก `pressed.emit()` เพื่อทดสอบ wiring ไม่เท่ากับการคลิกด้วยเมาส์จริงทุกตำแหน่งบน Windows

## Campaign exhaustive traversal

`tests/CampaignRunner.tscn`:

- **4,096/4,096** ชุดตัวเลือกเดินถึงจุดจบ โดยเลือก 2 คำตอบที่ decision ทั้ง 12 จุด
- **164/164** visible nodes เข้าถึงได้ (152 dialogue +12 choice)
- ฉากจบครบ **4/4**; ทุกเส้นทางผ่าน dialogue 104 หน้า
- **0 failures** และ condition cycle หยุดพร้อม error ที่อ่านได้
- Ending distribution: names 608, dawn 1,206, solitary 842, borrowed 1,440

นี่พิสูจน์ graph/ผลค่าสถานะ/เงื่อนไขจบ ไม่ใช่การให้มนุษย์อ่านประเมินคุณภาพภาษา 4,096 รอบ

## Persistence ข้าม process

`tests/PersistenceRunner.tscn -- --write` บันทึกหลัง c1_help แล้วปิดโปรแกรม

`tests/PersistenceRunner.tscn -- --read` เปิด Main ใหม่และโหลด: current node `a1_help_0`, HP90, history=[c1_help]. **ผ่าน** โดยไม่ apply effect รอบสอง. ใช้ไฟล์ test slot และลบทิ้งหลังตรวจ ไม่แตะ save_01 ของผู้เล่น

## Visual checks

ตรวจ screenshot ของ dialogue/choices/ending จริงที่ 1280×720, 960×540 และ 1920×1080. อ่านไทยและอังกฤษได้ ปุ่มไม่หลุดจอ. ภาพอยู่ใน `docs/design/`

พบปัญหา Latin fallback และ `Rect2i size is negative` จากเส้นทาง raster glyph ของ engine ระหว่างพัฒนา แก้เป็น Sarabun ที่มีไทย/Latin ในไฟล์เดียวและเปิด MSDF ใน `.ttf.import`. การ capture หลังแก้ไม่มี ERROR. มี warning เรื่อง V-Sync ของ virtual display ซึ่งไม่ทำให้เกมหยุด

Forward+ ทดลองเปิดแล้วพบ `VK_KHR_surface not found`; Godot fallback เป็น OpenGL. จึงยังไม่ถือว่าผ่าน visual QA ด้วย Forward+ แม้คงค่า default ตามสเปก

## Checklist ที่ Owner ต้องตรวจบน Windows

- [ ] Import Godot 4.6.3 ไม่มี error และกด F5 เล่นได้
- [ ] Forward+ บน GPU จริง หรือเลือก Compatibility
- [ ] คลิกปุ่มจริงทุกประเภท, Tab/Enter, Space, ลูกศร
- [ ] กดเริ่มใหม่ → ยกเลิก → ไม่เสียความคืบหน้า; ยืนยัน → reset
- [ ] Save/Load ใน user data directory ของ Windows และข้ามการเปิดโปรแกรม
- [ ] F11 และ resize หลายอัตราส่วน, Windows DPI scaling
- [ ] อ่านเนื้อเรื่องอย่างน้อยหนึ่งเส้นทางและตรวจคำผิด/ความต่อเนื่อง
- [ ] Export Windows Desktop แล้วรันบนเครื่องที่ไม่มี Editor

ยังไม่มี Windows executable ที่ผ่าน QA, audio tests, exploration tests, battle tests หรือ timeline tests เพราะระบบเหล่านั้นยังไม่สร้าง
