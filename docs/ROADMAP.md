> เอกสารพื้นฐานรุ่น 0.3 — สถานะล่าสุดและการเปลี่ยน entry point ดู [Visual Edition 0.4](VISUAL_EDITION_04.md)

# Roadmap และ Known Limitations

## ส่งมอบใน v0.3

Project Setup / GameState / Dialogue / Choices / StoryManager / Condition routing / Save v1 / Thai fonts / เรื่อง 6 ตอน / regression tests / exhaustive campaign traversal

## ยังไม่สร้าง

- Exploration: CharacterBody3D, Sprite3D billboard, collision, interaction, map transition
- Character system: portraits จริง, expression assets, animation states, relationship event UI
- Event system ทั่วโลกและ conditional choices แบบล็อก/ซ่อน
- Turn-based BattleManager, enemy AI, skills, buffs/debuffs
- TimelineManager, checkpoints, death-return, persistent memory policy
- Settings persistence, text-size settings, auto advance, backlog, save slots, autosave
- Audio buses/เสียง, scene transition polish, production art
- Windows export และ QA บนฮาร์ดแวร์เป้าหมาย

## ขั้นถัดไปที่เสนอ

1. Owner เล่นบทนำและตรวจโทนภาษา ความยาว ความสมเหตุสมผลของแต่ละผลลัพธ์
2. ตรวจ Windows: renderer, Thai, keyboard, fullscreen และ save directory
3. เพิ่ม backlog/หลายช่องบันทึกก่อนเพิ่ม campaign ยาวกว่านี้
4. สร้างแผนที่ 2.5D หนึ่งห้อง + เดิน + interaction ที่เปิด StoryManager เดิม
5. ทำ event/relationship checks แล้วค่อยเพิ่ม combat encounter เดียว
6. กำหนด reset/persistence rules เป็นเอกสาร ก่อนเริ่ม timeline mechanics

## ข้อจำกัดปัจจุบัน

- Save 1 ช่องพร้อม backup ก่อนหน้า ไม่มี cloud save/autosave; ผู้เล่นต้องกดบันทึกเอง
- โหลดกลางประโยคจะเริ่ม typewriter ของ node นั้นใหม่ ไม่จำจำนวนอักษรที่แสดง
- Settings ความเร็ว/เต็มจอไม่คงอยู่หลังปิดโปรแกรม
- Story ต้องอยู่ใน campaign ที่โหลดอยู่; ไม่ switch chapter file จาก Save โดยอัตโนมัติ
- ข้อมูล save version อื่นถูกปฏิเสธ ไม่มี migration จาก format ที่ยังไม่เคยปล่อย
- Forward+ ตั้งตามสเปก แต่เครื่อง Linux ทดสอบไม่มี Vulkan surface จึงตรวจภาพด้วย Compatibility
- ไม่มี art final และไม่มีเสียง; 3D World ยังเป็น scaffold
- โค้ด baseline บาง Dictionary เป็น public จึงควรใช้ mutation API แทนแก้ค่าตรง ๆ

หากเปลี่ยนสถาปัตยกรรม/ลบ node ให้ commit แยกพร้อมเหตุผลและทดสอบ Save เก่า. Rollback ใช้ checkout commit/tag ก่อนหน้า อย่าแก้ข้อมูล Save ของผู้เล่นโดยไม่สำรอง
