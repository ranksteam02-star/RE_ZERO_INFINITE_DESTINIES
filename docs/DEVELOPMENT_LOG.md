# Development Log

## ชุดงาน v0.3

เริ่มงาน: 2026-11-07 (Asia/Bangkok ตามวันเริ่ม session)

- ตรวจเอกสารที่แนบและรายละเอียดจาก shared chat ที่ Owner คัดลอกมา
- สร้างโครงไฟล์, project settings, Main, GameState Autoload
- สร้าง dialogue presentation / typewriter / fonts / original placeholder assets
- เพิ่ม StoryManager และ JSON graph validation
- เพิ่ม ChoiceSystem, effects, stale-selection protection, 2-branch regression story
- เพิ่ม Save v1 พร้อม temp file, prior backup, schema validation และ recovery
- ขยายเรื่องเป็น 6 ตอน, 152 dialogue nodes, 12 choices, 4 condition nodes, 4 endings
- เพิ่ม condition routing สำหรับผลระยะยาวและ ending requirements
- เพิ่ม New Game confirmation และ toolbar สำหรับ Save/Load/speed/fullscreen
- แก้ font fallback และ glyph rendering โดยใช้ Sarabun + MSDF หลังตรวจ screenshot จริง
- เพิ่ม tests หลัก, campaign enumeration และ cross-process persistence
- จัดทำคู่มือ setup/authoring/architecture/QA/roadmap/asset credits

ไฟล์ใหม่ทั้งหมดอยู่ใน source project ไม่มีไฟล์โปรเจกต์เดิมให้แก้ทับ. ผลทดสอบสุดท้ายและข้อจำกัดแยกไว้ใน TEST_RESULTS.md

Pending: GitHub private upload หลัง repository ถูกสร้างและ grant access; Windows export/device QA; Owner playtest เนื้อเรื่อง
