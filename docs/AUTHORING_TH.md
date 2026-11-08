# คู่มือเขียนเนื้อเรื่องด้วย JSON

ไฟล์หลัก `data/stories/the_thirteenth_bell.json`. เก็บ UTF-8; สำรองหรือ commit ก่อนแก้. JSON ไม่รองรับ comment และห้ามใส่ comma หลังสมาชิกสุดท้าย

## โครงเรื่อง

```json
{
  "chapter_id": "my_story",
  "start_node": "start",
  "nodes": {
    "start": {"type":"dialogue", "speaker":"ผู้บรรยาย", "text":"เรื่องเริ่มต้น", "next_node":"decision"},
    "decision": {"type":"choice", "text":"คุณจะทำอะไร?", "choices":[
      {"id":"help", "text":"ช่วย", "effects":[{"type":"story_flag","key":"helped","value":true}], "next_node":"end"},
      {"id":"observe", "text":"เฝ้าดู", "effects":[], "next_node":"end"}
    ]},
    "end": {"type":"dialogue", "speaker":"ผู้บรรยาย", "text":"จบฉาก", "next_node":""}
  }
}
```

ทุก node ID ต้องไม่ซ้ำ และทุก choice ID ต้องไม่ซ้ำทั้งไฟล์ JSON object keys ซ้ำอาจถูก parser ทับ จึงควรใช้ editor ที่ตรวจ duplicate keys ก่อนรัน

## Dialogue node

Required: `type=dialogue`, `speaker`, `text`, `next_node` เป็น String. next_node ว่างหมายถึงจบเรื่องหลังผู้เล่นกดต่อ ไม่ใช่ข้ามไปเรื่องอื่นอัตโนมัติ

Optional: `portrait`, `background`, `chapter_title`. ภาพต้องเป็น Texture2D ที่ import แล้วใต้ `res://assets/`; ค่าว่างหมายถึงล้างภาพเดิม. `chapter_title` แสดงหัวตอนด้านบน. ถ้าทำฉากใหม่ต้องกำหนด background ในทุกหน้า ไม่พึ่งภาพค้างจากหน้าที่แล้ว

แนะนำ 1–3 ประโยคต่อหน้า ข้อความยาวเลื่อนได้ในกรอบ แต่ไม่ควรยัดย่อหน้าทั้งบทลง node เดียว ใช้ `\n` ใน JSON เมื่อต้องการขึ้นบรรทัดใหม่

## Choice node และผลกระทบ

Required: `text` เป็นคำถาม, `choices` เป็น Array ที่ไม่ว่าง. แต่ละ choice ต้องมี `id`, `text`, `effects`, `next_node`

รองรับ effects เฉพาะ:

```json
[
  {"type":"player_stat", "key":"hp", "amount":-10},
  {"type":"relationship", "character":"emilia", "key":"trust", "amount":10},
  {"type":"story_flag", "key":"rescued_nerin", "value":true}
]
```

ผลจะ apply ตามลำดับก่อนเปลี่ยน node. ใช้ amount จำนวนเต็ม; key ของ player ต้องมีใน GameState. Relationship key มี 5 แบบตาม TDD. ไม่มี effect แบบรันโค้ดหรือเปิดไฟล์

Choice conditions สำหรับซ่อน/ล็อกตัวเลือกยังไม่ได้สร้าง รุ่นนี้ให้ใช้ condition node แตกเส้นทางไปยัง choice node ที่ต่างกันแทน อย่าใส่ `conditions` แล้วคาดว่าระบบจะประเมินเอง

## Condition node

```json
{
  "type":"condition",
  "condition":{"type":"relationship","character":"emilia","key":"trust","gte":20},
  "if_true":"trusted_route",
  "if_false":"distant_route"
}
```

เงื่อนไขอื่น:

- `{ "type":"stat", "key":"knowledge", "gte":18 }`
- `{ "type":"flag", "key":"distributed_records", "value":true }`

รองรับ >= สำหรับตัวเลข และเท่ากับสำหรับ bool. ถ้าต้องการ AND ให้ต่อ condition หลาย node. Condition ไม่แสดงหน้า UI และไม่เปลี่ยนค่า ใช้เฉพาะเลือกปลายทาง

## เพิ่มตอนใหม่อย่างปลอดภัย

1. เพิ่ม dialogue IDs ชุดใหม่ เช่น `chapter07_00` ถึง `chapter07_05`
2. เชื่อม next_node สุดท้ายของตอนก่อนเข้าตอนใหม่
3. ตั้ง chapter_title ของหน้าทั้งตอน ไม่จำเป็นต้องเปลี่ยน chapter_id ของ campaign
4. เพิ่ม choices/flags เฉพาะที่มีผลจริง เขียนผลระยะสั้นและระยะยาวไว้ใน story guide
5. ตรวจปลายทางทั้งหมดและ duplicate choice IDs
6. เล่นแต่ละแขนงด้วยตัวเอง และเพิ่ม route tests ให้ตรงจำนวน choices ใหม่
7. หากเปลี่ยน/ลบ node ที่ Save เก่าอ้างถึง ต้องมี migration หรือแจ้งว่า Save เก่าไม่รองรับ
8. รัน test suite แล้ว commit source พร้อมเอกสาร

Campaign test ปัจจุบัน enumerate 2^12 รูปแบบตาม choice 12 จุด จุดละ 2 คำตอบ หากเพิ่มตัวเลือกสามคำตอบ, เส้นทางข้าม choice หรือจำนวน choice เปลี่ยน ต้องแก้ traversal strategy ก่อนใช้ตัวเลข 4,096 อ้างความครอบคลุม

## เนื้อหาและทรัพยากร

สุบารุ/เอมิเลียเป็นตัวละครจาก Re:Zero; เนริน/ลิออร่า/ออร์เวนและเหตุการณ์ระฆังเป็นเนื้อหาต้นแบบสร้างใหม่ ไม่อ้างว่าเป็น canon ภาพ portrait เป็นสัญลักษณ์ placeholder ไม่ใช่ภาพตัวละครอย่างเป็นทางการ

จะเปลี่ยนภาพ: วางไฟล์ที่มีสิทธิ์ใช้ใน assets → รอ import → แก้ path ใน JSON. จะเพิ่มท่าทาง: ตอนนี้ใช้ portrait path ต่างกันได้ ยังไม่มี expression controller โดยเฉพาะ
