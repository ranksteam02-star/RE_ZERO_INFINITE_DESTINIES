extends Node3D

signal interaction_requested
var active: bool = false
var player: CharacterBody3D
var visual: Sprite3D
var npc: Sprite3D
var camera: Camera3D
var lamps: Array[OmniLight3D] = []
var motes: Array[MeshInstance3D] = []
var phase: float = 0.0
var npc_position := Vector3(2.4, 0, 0.3)
var spawn_point := Vector3(0, 0, 5.5)
var near_npc: bool = false
var materials: Dictionary = {}

func _ready() -> void:
    _build_environment()
    _build_plaza()
    _build_characters()
    _build_camera()

func material(color: Color, glow: bool = false) -> StandardMaterial3D:
    var key: String = str(color) + str(glow)
    if materials.has(key):
        return materials[key]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.83
    if glow:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 0.55
    materials[key] = mat
    return mat

func box(pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.material_override = material(color)
    instance.position = pos
    add_child(instance)
    if solid:
        collider(pos, size)
    return instance

func collider(pos: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    var resource := BoxShape3D.new()
    resource.size = size
    shape.shape = resource
    body.position = pos
    body.add_child(shape)
    add_child(body)

func cylinder(pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 32
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.material_override = material(color)
    instance.position = pos
    add_child(instance)
    return instance

func _build_environment() -> void:
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("202b47")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("899ac2")
    environment.ambient_light_energy = 0.28
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    var world_environment := WorldEnvironment.new()
    world_environment.environment = environment
    add_child(world_environment)
    var moon := DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-52, -35, 0)
    moon.light_color = Color("bcc8ff")
    moon.light_energy = 0.48
    moon.shadow_enabled = true
    add_child(moon)
    var warm := DirectionalLight3D.new()
    warm.rotation_degrees = Vector3(-25, 140, 0)
    warm.light_color = Color("f0b17d")
    warm.light_energy = 0.20
    add_child(warm)

func _build_plaza() -> void:
    box(Vector3(0, -0.35, 0), Vector3(29, 0.7, 25), Color("363f53"), true)
    # Alternating inset stone tiles; deterministic layout, no external models.
    for x in range(-13, 14):
        for z in range(-3, 11):
            var shade: float = float(posmod(x * 7 + z * 11, 5)) * 0.012
            box(Vector3(x, 0.012, z), Vector3(0.96, 0.025, 0.96), Color(0.34 + shade, 0.34 + shade, 0.39 + shade))
    box(Vector3(0, 0.025, -5), Vector3(28, 0.045, 3.2), Color("235e75"))
    for i in range(18):
        box(Vector3(-13 + i * 1.5, 0.055, -4.6 - (i % 3) * 0.4), Vector3(0.7, 0.01, 0.025), Color("5d98a4"))
    for side in [-1, 1]:
        box(Vector3(side * 8, 0.32, -3.3), Vector3(11, 0.65, 0.22), Color("b4a79b"), true)
        box(Vector3(side * 8, 0.32, -6.7), Vector3(11, 0.65, 0.22), Color("b4a79b"), true)
        collider(Vector3(side * 8, 0.2, -5), Vector3(11, 2, 3.1))
    box(Vector3(0, 0.08, -5), Vector3(4.5, 0.16, 4.2), Color("b2a38d"))
    for side in [-1, 1]:
        for z in range(-7, -2):
            box(Vector3(side * 2.2, 0.55, z), Vector3(0.18, 1.1, 0.18), Color("d3bb94"), true)
        box(Vector3(side * 2.2, 1.05, -5), Vector3(0.16, 0.16, 4.3), Color("d3bb94"))
    # Fountain with raised basin, central column and glowing pool.
    cylinder(Vector3(-2.8, 0.12, 0), 2.15, 0.24, Color("9d8e89"))
    cylinder(Vector3(-2.8, 0.38, 0), 1.8, 0.52, Color("a39792"))
    cylinder(Vector3(-2.8, 0.66, 0), 1.58, 0.04, Color("4d929b"))
    cylinder(Vector3(-2.8, 1.15, 0), 0.25, 1.1, Color("c6b6a4"))
    cylinder(Vector3(-2.8, 1.7, 0), 0.78, 0.18, Color("c6b6a4"))
    cylinder(Vector3(-2.8, 1.81, 0), 0.68, 0.04, Color("71bac1"))
    collider(Vector3(-2.8, 0.5, 0), Vector3(3.7, 1, 3.7))
    for i in range(8):
        var angle: float = i * TAU / 8.0
        cylinder(Vector3(-2.8 + cos(angle) * 0.6, 1.28, sin(angle) * 0.6), 0.025, 0.85, Color("8cced1"))
    var palette := [Color("b59b96"), Color("b1aaa3"), Color("b8a892"), Color("9fa6b7")]
    for i in range(5):
        house(Vector3(-11.5 + i * 5.6, 0, -10), 4.7, 4.4 + (i % 2) * 0.7, palette[i % 4])
    house(Vector3(-11, 0, 1), 4.8, 5.5, palette[0])
    house(Vector3(11, 0, 1), 4.8, 5, palette[2])
    # Bell tower silhouettes the plaza.
    box(Vector3(8.8, 4.8, -9.5), Vector3(3.4, 9.6, 3.4), Color("a99ca9"), true)
    for y in [2.0, 5.2, 8.3]:
        box(Vector3(8.8, y, -7.74), Vector3(3.7, 0.18, 0.3), Color("d8c4ad"))
    for x in [7.9, 9.7]:
        box(Vector3(x, 7.3, -7.77), Vector3(0.65, 1.3, 0.05), Color("273451"))
    var clock := cylinder(Vector3(8.8, 5.9, -7.68), 0.75, 0.08, Color("ead4a3"))
    clock.rotation_degrees.x = 90
    box(Vector3(8.8, 6.16, -7.61), Vector3(0.07, 0.53, 0.07), Color("353547"))
    box(Vector3(9.03, 5.9, -7.61), Vector3(0.48, 0.07, 0.07), Color("353547"))
    roof(Vector3(8.8, 10.4, -9.5), Vector3(4.3, 2.6, 4.3))
    for pos in [Vector3(-6.5, 0, 4.8), Vector3(6.5, 0, 4.8), Vector3(-6.5, 0, -2.4), Vector3(6.5, 0, -2.4), Vector3(1, 0, -7.6)]:
        lantern(pos)
    for side in [-1, 1]:
        for z in [1.7, 6.5]:
            var pos := Vector3(side * 8, 0, z)
            box(pos + Vector3(0, 0.3, 0), Vector3(1.6, 0.6, 0.8), Color("745554"), true)
            for i in range(5):
                var flower := cylinder(pos + Vector3(-0.6 + i * 0.3, 0.85, 0), 0.22, 0.45, Color("788b85"))
                flower.material_override = material(Color("9f7ead") if i % 2 == 0 else Color("b3a6ca"))
    # Low cost firefly motes, animated independently from player control.
    for i in range(26):
        var sphere := SphereMesh.new()
        sphere.radius = 0.025
        sphere.height = 0.05
        var mote := MeshInstance3D.new()
        mote.mesh = sphere
        mote.material_override = material(Color("f8d391"), true)
        mote.position = Vector3(sin(i * 4.2) * 8, 0.8 + fmod(i * 0.39, 2.2), cos(i * 2.7) * 6)
        add_child(mote)
        motes.append(mote)
    collider(Vector3(-14.5, 1, 0), Vector3(1, 3, 26))
    collider(Vector3(14.5, 1, 0), Vector3(1, 3, 26))
    collider(Vector3(0, 1, 11.5), Vector3(30, 3, 1))
    collider(Vector3(0, 1, -12), Vector3(30, 3, 1))

func roof(pos: Vector3, size: Vector3) -> void:
    var mesh := PrismMesh.new()
    mesh.size = size
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.material_override = material(Color("4a4566"))
    instance.position = pos
    add_child(instance)

func house(pos: Vector3, width: float, height: float, color: Color) -> void:
    box(pos + Vector3(0, height / 2, 0), Vector3(width, height, 3.4), color, true)
    roof(pos + Vector3(0, height + 0.75, 0), Vector3(width + 0.6, 1.8, 4.1))
    for x in [-width * 0.46, 0.0, width * 0.46]:
        box(pos + Vector3(x, height / 2, 1.73), Vector3(0.16, height, 0.12), Color("514353"))
    for y in [0.3, height * 0.5, height - 0.1]:
        box(pos + Vector3(0, y, 1.73), Vector3(width, 0.16, 0.12), Color("514353"))
    for x in [-width * 0.25, width * 0.25]:
        for y in [1.1, height - 1.0]:
            var window := box(pos + Vector3(x, y, 1.78), Vector3(0.83, 1.05, 0.06), Color("f5c08a"))
            window.material_override = material(Color("edbd81"), true)
            box(pos + Vector3(x, y, 1.83), Vector3(0.07, 1.09, 0.06), Color("635053"))
            box(pos + Vector3(x, y, 1.83), Vector3(0.87, 0.07, 0.06), Color("635053"))
    box(pos + Vector3(0, 0.9, 1.79), Vector3(0.8, 1.8, 0.12), Color("3e394b"))

func lantern(pos: Vector3) -> void:
    cylinder(pos + Vector3(0, 1.25, 0), 0.06, 2.5, Color("3a3548"))
    cylinder(pos + Vector3(0, 0.1, 0), 0.25, 0.2, Color("5f5463"))
    var light_box := box(pos + Vector3(0, 2.65, 0), Vector3(0.38, 0.5, 0.38), Color("ffcc85"))
    light_box.material_override = material(Color("ffd59b"), true)
    roof(pos + Vector3(0, 3.0, 0), Vector3(0.65, 0.3, 0.65))
    var light := OmniLight3D.new()
    light.position = pos + Vector3(0, 2.5, 0)
    light.light_color = Color("ffc484")
    light.light_energy = 0.8
    light.omni_range = 5.5
    add_child(light)
    lamps.append(light)

func sprite(path: String) -> Sprite3D:
    var result := Sprite3D.new()
    result.texture = load(path)
    result.pixel_size = 0.0028
    result.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    result.no_depth_test = false
    result.shaded = false
    result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
    return result

func _build_characters() -> void:
    player = CharacterBody3D.new()
    player.position = spawn_point
    add_child(player)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.3
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    player.add_child(collision)
    visual = sprite("res://assets/art/subaru.tres")
    visual.position.y = 1.35
    player.add_child(visual)
    npc = sprite("res://assets/art/emilia.tres")
    npc.position = npc_position + Vector3(0, 1.35, 0)
    add_child(npc)
    var label := Label3D.new()
    label.font = load("res://assets/fonts/Sarabun-Regular.ttf")
    label.font_size = 48
    label.text = "เอมิเลีย"
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.position = npc_position + Vector3(0, 3.0, 0)
    label.modulate = Color("f4d9a9")
    add_child(label)

func _build_camera() -> void:
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 20.0
    camera.position = Vector3(14, 19, 23)
    add_child(camera)
    camera.look_at(Vector3(0, 0.5, -1))
    camera.current = true

func _physics_process(delta: float) -> void:
    if player == null:
        return
    var direction := Vector3.ZERO
    if active:
        var input := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
        var right: Vector3 = camera.global_basis.x
        var forward: Vector3 = camera.global_basis.z
        right.y = 0
        forward.y = 0
        direction = (right.normalized() * input.x + forward.normalized() * input.y).normalized()
    player.velocity.x = direction.x * 4.3
    player.velocity.z = direction.z * 4.3
    player.velocity.y -= 18.0 * delta
    player.move_and_slide()
    near_npc = player.position.distance_to(npc_position) < 2.4
    if direction.length() > 0.1:
        visual.position.y = 1.35 + sin(phase * 11) * 0.035
    else:
        visual.position.y = 1.35

func _process(delta: float) -> void:
    if not visible:
        return
    phase += delta
    for i in range(motes.size()):
        var mote := motes[i]
        mote.position.y += sin(phase * 0.9 + i) * delta * 0.08
    for i in range(lamps.size()):
        lamps[i].light_energy = 0.8 + sin(phase * 2.5 + i) * 0.05

func try_interact() -> bool:
    if active and near_npc:
        interaction_requested.emit()
        return true
    return false
