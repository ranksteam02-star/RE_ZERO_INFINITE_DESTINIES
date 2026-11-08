# Decision Log

## ข้อกำหนดของ Owner

Godot 4 / GDScript / Windows / Thai / modular data-driven / 2.5D 3D environment + 2D characters / Forward+ / Solo Developer. ขอโปรเจกต์ละเอียดที่เล่นได้จริง เนื้อเรื่องยาว และจัดเก็บบน GitHub private

## การตัดสินใจสำหรับ v0.3

- เริ่มจากไฟล์ใหม่ เพราะไม่มี existing project ใน workspace; ไม่อ้างว่า baseline ที่แนบมารันแล้วก่อนเริ่ม
- ใช้ Godot 4.6.3 ที่ติดตั้งจริง และรันตรวจ parse/runtime
- รักษา public baseline GameState API เพิ่ม max_hp/stamina/mental bounds และ snapshot/restore เพื่อป้องกันข้อมูลเสีย
- ขยายจาก dialogue-only ไปถึง choices/conditions/save เพื่อส่งมอบ playable loop ตามคำขอเพิ่มเติม
- มี 6 ตอน/4 endings ใน JSON เดียว เพื่อลดการจัดการ file transition ก่อนจำเป็น
- ใช้ branch-and-rejoin เพื่อเพิ่มผลลัพธ์โดยไม่ทำให้จำนวนบทสนทนาเติบโตเกิน solo scope
- ไม่สร้าง battle/timeline/exploration พร้อมกัน; placeholder ไม่ถูกนับว่าเป็นระบบเสร็จ
- New Game มี confirmation เพราะเนื้อเรื่องยาว; ไม่ลบ Save เดิมเมื่อเริ่มใหม่
- แยกฉากสั้นเป็น test fixture ใช้ Save filenames คนละชื่อกับของผู้เล่น
- เปลี่ยนฟอนต์สุดท้ายเป็น Sarabun (ไทย/Latin ในไฟล์เดียว) และเปิด MSDF หลังตรวจภาพพบปัญหา Latin fallback และ Rect2i ใน raster path. หลังแก้ capture ทั้งสามขนาดไม่มี ERROR
- คง Forward+ ในโปรเจกต์ แต่ภาพ QA ใช้ Compatibility เนื่องจาก Vulkan ของ executor ไม่พร้อม

## GitHub publication

Owner อนุญาต private repository. Account ที่เชื่อมคือ ranksteam02-star. การสร้าง repository ใหม่ถูก GitHub ปฏิเสธ `Resource not accessible by integration (createRepository)`; ไม่ใช่ auto-review rejection. ไม่อัปโหลดไป repository อื่นที่ไม่เกี่ยวข้อง และไม่เปลี่ยน privacy ของ repository เดิม
