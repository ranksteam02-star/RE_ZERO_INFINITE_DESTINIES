# Living Town 0.5

Overworld characters use 1536×1024 transparent sprite sheets, six columns and four rows. Rows face down/left/right/up. Columns 0–1 provide idle/blink; 2–5 contain four distinct walking poses. Runtime uses AtlasTexture regions and AnimatedSprite3D at 8 fps. Facing comes from actual world velocity projected onto the camera axes, so blocked movement returns to idle. Characters occupy roughly 1.8 world units; dialogue portraits are unchanged.

City additions: staggered stone shader, tiled roofs, continuous time-based water shader, eight CPU-particle fountain jets, subdivided cloth banners, trees, flower boxes, benches and contact shadows. These run in the release Compatibility renderer without external services. Each actor has eight animations; idle blink loops automatically. This release does not add new story hours or a larger map.

Verification: existing 43 core and 19 shell checks; exhaustive campaign routes; persistence round trip. `tests/motion_capture.gd` drives physical input in four directions and asserts walking frame advancement and idle transitions, then captures actual rendered frames. Run with a graphical display and Compatibility renderer. The Windows binary is exported using official Godot templates; runtime verification is on Linux.

Art: newly generated Subaru and Emilia chibi motion sheets for this fan prototype, separate from visual-novel portrait art. No official game sprite extraction. RE:ZERO characters belong to their respective rights holders.
