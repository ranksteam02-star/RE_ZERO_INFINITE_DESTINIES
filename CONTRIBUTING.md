# ร่วมพัฒนา

ใช้ Godot 4.6.3 Standard และเริ่มอ่าน README.md / docs/SETUP_TH.md

1. Fork repository หรือสร้าง branch ถ้ามีสิทธิ์เขียน
2. แยกการแก้แต่ละเรื่องเป็น commit ที่ตรวจสอบได้
3. หากแก้บทสนทนา อ่าน docs/AUTHORING_TH.md; อย่าเปลี่ยน node ID เดิมโดยไม่พิจารณา Save ที่อ้างถึง
4. หากแก้ระบบ ให้รัน tests/run_all.sh หรือ tests/run_all.bat แล้วแนบผลใน Pull Request
5. อธิบายสิ่งที่เปลี่ยน เหตุผล วิธีทดสอบ และผลต่อ Save เดิม
6. ส่ง Pull Request เข้า main ให้ Owner ตรวจ ก่อน merge

อย่า commit .godot/, Save ผู้เล่น, token, credential หรือ asset ที่ไม่มีสิทธิ์ใช้. เงื่อนไขของฟอนต์อยู่ใน assets/fonts/Sarabun-OFL.txt. Public repository เปิดให้เสนอการเปลี่ยนแปลงผ่าน Fork/Pull Request; การ push โดยตรงต้องได้รับสิทธิ์จาก Owner.

บทสนทนาเป็นภาษาไทย โค้ดและชื่อ identifier เป็นภาษาอังกฤษ. ระบบ battle และ timeline ยังไม่สร้าง; exploration มีลานเมืองหนึ่งฉากแล้ว อย่านับโฟลเดอร์ placeholder ว่าเป็นฟีเจอร์ที่ทำงานแล้ว.
