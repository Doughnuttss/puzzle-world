extends Node3D

## Procedural greybox for Hermes — The Cloud Bridge.
## Five floating marble discs (central plaza + four diagonal islands) over a cloud void.
## Zone 1 hosts a stick + anamorph sandwich prototype; other zones deferred.

const HermesAnamorphStationScript := preload("res://worlds/courts/hermes/hermes_anamorph_station.gd")
const HermesPuzzleDataScript := preload("res://worlds/courts/hermes/hermes_puzzle_data.gd")

const ZONE5_RADIUS := 8.5
const OUTER_RADIUS := 5.0
const RING_RADIUS := 19.0
const BRIDGE_LENGTH := 11.0
## Longer approach from hub spawn into the central plaza.
const SPAWN_BRIDGE_LENGTH := 17.0
const BRIDGE_WIDTH := 2.4
const BRIDGE_DECK_THICKNESS := 0.28
const PLATFORM_THICKNESS := 0.55
## Short visible lip; tall invisible wall so jumps cannot clear the rim.
const CURB_HEIGHT := 0.22
const CURB_THICKNESS := 0.2
const BARRIER_HEIGHT := 2.6
const BARRIER_THICKNESS := 0.22
## Flat apron into each disc so circle/straight joins have no floor or curb gap.
const LANDING_INSET := 0.7
const LANDING_OVERLAP := 0.08
## Large arrival plaza on the north approach.
const SPAWN_PAD_W := 14.0
const SPAWN_PAD_D := 12.0

## Outer islands sit lower than the center for sky-temple drama.
const ZONE5_Y := 0.0
const OUTER_Y := -2.0
const SPAWN_Y := 0.0

## Degrees from +Z (north); + toward +X (east). Matches layout canvas / concept art.
const ZONE_ANGLES := {
	1: -45.0,
	2: 45.0,
	3: 135.0,
	4: -135.0,
}


func _ready() -> void:
	_build_court()


func _build_court() -> void:
	for child in get_children():
		if child.has_meta("generated_hermes"):
			child.queue_free()

	var marble := _mat_stone(Color(0.92, 0.9, 0.86), 0.78)
	var marble_dark := _mat_stone(Color(0.78, 0.76, 0.72), 0.85)
	var gold := _mat_stone(Color(0.82, 0.68, 0.32), 0.45, 0.55)
	var curb := _mat_curb_solid()
	var cloud := _mat_stone(Color(0.88, 0.9, 0.95), 0.98)

	_build_cloud_underlay(cloud)
	_build_zone_disc(5, Vector3(0.0, ZONE5_Y, 0.0), ZONE5_RADIUS, marble, marble_dark, gold, curb, true)
	for zone_id in ZONE_ANGLES.keys():
		var deg: float = float(ZONE_ANGLES[zone_id])
		var pos := _ring_point(deg, RING_RADIUS)
		pos.y = OUTER_Y
		_build_zone_disc(int(zone_id), pos, OUTER_RADIUS, marble, marble_dark, gold, curb, false)
		_build_bridge_to_center(int(zone_id), pos, OUTER_RADIUS, ZONE5_RADIUS, ZONE5_Y, marble, curb)

	_build_spawn_approach(marble, marble_dark, gold, curb)


func _mark(node: Node) -> void:
	node.set_meta("generated_hermes", true)
	add_child(node)


func _mat_stone(color: Color, rough: float = 0.88, metallic: float = 0.05) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metallic
	return m


func _mat_curb_solid() -> StandardMaterial3D:
	## Opaque matte rim — not glassy / see-through.
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.78, 0.58, 0.2, 1.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	m.roughness = 0.72
	m.metallic = 0.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


func _ring_point(deg_from_north: float, radius: float) -> Vector3:
	var rad := deg_to_rad(deg_from_north)
	return Vector3(sin(rad) * radius, 0.0, cos(rad) * radius)


func _build_cloud_underlay(mat: Material) -> void:
	var cloud := MeshInstance3D.new()
	cloud.name = "CloudUnderlay"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 48.0
	mesh.bottom_radius = 52.0
	mesh.height = 1.2
	cloud.mesh = mesh
	cloud.material_override = mat
	cloud.position = Vector3(0.0, -14.0, 0.0)
	_mark(cloud)

	# Soft fill light from below so platforms don't silhouette as hard black.
	var up_light := OmniLight3D.new()
	up_light.name = "CloudBounce"
	up_light.light_color = Color(0.75, 0.82, 0.95)
	up_light.light_energy = 1.4
	up_light.omni_range = 40.0
	up_light.position = Vector3(0.0, -8.0, 0.0)
	_mark(up_light)


func _build_zone_disc(
	zone_id: int,
	pos: Vector3,
	radius: float,
	marble: Material,
	marble_dark: Material,
	gold: Material,
	curb_mat: Material,
	is_center: bool
) -> void:
	var root := StaticBody3D.new()
	root.name = "Zone_%d" % zone_id
	root.collision_layer = 1
	root.collision_mask = 0
	root.position = pos
	root.set_meta("hermes_zone_id", zone_id)

	# Main disc.
	var disc := MeshInstance3D.new()
	disc.name = "Disc"
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = radius
	disc_mesh.bottom_radius = radius * 1.02
	disc_mesh.height = PLATFORM_THICKNESS
	disc.mesh = disc_mesh
	disc.material_override = marble
	disc.position = Vector3(0.0, -PLATFORM_THICKNESS * 0.5, 0.0)
	root.add_child(disc)

	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = PLATFORM_THICKNESS
	shape.shape = cyl
	shape.position = disc.position
	root.add_child(shape)

	# Inner ring pattern on center plaza.
	if is_center:
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = radius * 0.48
		ring_mesh.outer_radius = radius * 0.52
		ring.mesh = ring_mesh
		ring.material_override = marble_dark
		ring.position = Vector3(0.0, 0.02, 0.0)
		ring.rotation.x = PI * 0.5
		root.add_child(ring)

	# Gold rim lip.
	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = radius - 0.12
	rim_mesh.outer_radius = radius + 0.06
	rim.mesh = rim_mesh
	rim.material_override = gold
	rim.position = Vector3(0.0, 0.04, 0.0)
	rim.rotation.x = PI * 0.5
	root.add_child(rim)

	_add_rail_ring(root, radius - 0.02, curb_mat, _zone_rail_gap_yaws(zone_id, is_center, pos))

	var label := Label3D.new()
	label.name = "ZoneLabel"
	label.text = str(zone_id)
	label.font_size = 96 if is_center else 72
	label.pixel_size = 0.012
	label.position = Vector3(0.0, 0.15, 0.0)
	label.rotation.x = -PI * 0.5
	label.modulate = Color(0.55, 0.48, 0.28)
	label.outline_size = 8
	root.add_child(label)

	var title := Label3D.new()
	title.name = "ZoneTitle"
	if is_center:
		title.text = "Zone 5 — Central Plaza"
	else:
		title.text = "Zone %d" % zone_id
	title.font_size = 28
	title.pixel_size = 0.01
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0.0, 2.4, 0.0)
	title.modulate = Color(0.95, 0.9, 0.75)
	root.add_child(title)

	# Future puzzle mount hook.
	var marker := Marker3D.new()
	marker.name = "ZoneMarker_%d" % zone_id
	marker.position = Vector3(0.0, 0.05, 0.0)
	marker.set_meta("hermes_zone_id", zone_id)
	root.add_child(marker)

	if zone_id == 1:
		_build_zone1_anamorph_station(root, marble, gold)

	_mark(root)


func _build_zone1_anamorph_station(zone_root: Node3D, marble: Material, gold: Material) -> void:
	## Side view: rim → short vertical post → thin inward-tilted panel → small stick.
	var inward := Vector3(-zone_root.position.x, 0.0, -zone_root.position.z)
	if inward.length_squared() < 0.001:
		inward = Vector3(0.0, 0.0, -1.0)
	else:
		inward = inward.normalized()
	var outward := -inward

	var station := Node3D.new()
	station.name = "Zone1AnamorphStation"
	## On the true outer rim (Zone 1 is diagonal — not parent +Z).
	station.position = outward * OUTER_RADIUS
	## Local -Z toward plaza, +Z out toward the puzzle.
	station.basis = Basis.looking_at(-inward, Vector3.UP)
	zone_root.add_child(station)

	var console := StaticBody3D.new()
	console.name = "ControlStation"
	console.collision_layer = 1
	console.collision_mask = 0
	station.add_child(console)

	## Taller slim solid-color cylinder rising from the border.
	const POST_R := 0.07
	const POST_H := 0.78
	const POST_Z := 0.1
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.72, 0.48, 0.16)
	post_mat.roughness = 0.88
	post_mat.metallic = 0.0
	var post := MeshInstance3D.new()
	post.name = "StationPost"
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = POST_R
	post_mesh.bottom_radius = POST_R * 1.05
	post_mesh.height = POST_H
	post.mesh = post_mesh
	post.material_override = post_mat
	post.position = Vector3(0.0, POST_H * 0.5, POST_Z)
	console.add_child(post)

	var post_shape := CollisionShape3D.new()
	var post_cyl := CylinderShape3D.new()
	post_cyl.radius = POST_R * 1.1
	post_cyl.height = POST_H
	post_shape.shape = post_cyl
	post_shape.position = post.position
	console.add_child(post_shape)

	## Thin panel, tipped slightly toward the plaza (inward).
	const PANEL_W := 0.85
	const PANEL_D := 0.55
	const PANEL_H := 0.055
	const PANEL_TILT_DEG := 12.0
	var panel_pivot := Node3D.new()
	panel_pivot.name = "PanelPivot"
	panel_pivot.position = Vector3(0.0, POST_H, POST_Z)
	## Positive X rotation tips the far edge down / near edge up → faces inward/up a bit.
	panel_pivot.rotation_degrees = Vector3(PANEL_TILT_DEG, 0.0, 0.0)
	console.add_child(panel_pivot)

	var desk := MeshInstance3D.new()
	desk.name = "StationPanel"
	var desk_mesh := BoxMesh.new()
	desk_mesh.size = Vector3(PANEL_W, PANEL_H, PANEL_D)
	desk.mesh = desk_mesh
	desk.material_override = marble
	desk.position = Vector3(0.0, PANEL_H * 0.5, PANEL_D * 0.15)
	panel_pivot.add_child(desk)

	var desk_shape := CollisionShape3D.new()
	var desk_box := BoxShape3D.new()
	desk_box.size = Vector3(PANEL_W, PANEL_H, PANEL_D)
	desk_shape.shape = desk_box
	desk_shape.position = desk.position
	panel_pivot.add_child(desk_shape)

	## Compact contrast-colored stick (teal bronze — reads against gold/marble).
	var stick_mat := StandardMaterial3D.new()
	stick_mat.albedo_color = Color(0.12, 0.42, 0.48)
	stick_mat.roughness = 0.45
	stick_mat.metallic = 0.35

	var stick := HermesAnamorphStationScript.new()
	stick.name = "ControlStick"
	stick.position = Vector3(0.0, PANEL_H, PANEL_D * 0.15)
	panel_pivot.add_child(stick)

	var stick_mesh := MeshInstance3D.new()
	stick_mesh.name = "StickMesh"
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.028
	shaft.bottom_radius = 0.034
	shaft.height = 0.38
	stick_mesh.mesh = shaft
	stick_mesh.material_override = stick_mat
	stick_mesh.position = Vector3(0.0, 0.22, 0.0)
	stick.add_child(stick_mesh)

	var knob := MeshInstance3D.new()
	var knob_mesh := SphereMesh.new()
	knob_mesh.radius = 0.048
	knob_mesh.height = 0.096
	knob.mesh = knob_mesh
	knob.material_override = stick_mat
	knob.position = Vector3(0.0, 0.44, 0.0)
	stick.add_child(knob)

	var stick_shape := CollisionShape3D.new()
	var stick_box := BoxShape3D.new()
	stick_box.size = Vector3(0.35, 0.55, 0.35)
	stick_shape.shape = stick_box
	stick_shape.position = Vector3(0.0, 0.28, 0.0)
	stick.add_child(stick_shape)

	var hint := Label3D.new()
	hint.name = "StationHint"
	hint.text = "Rim station · face the sky board"
	hint.font_size = 18
	hint.pixel_size = 0.007
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.position = Vector3(0.0, 1.55, POST_Z)
	hint.modulate = Color(0.95, 0.88, 0.65)
	station.add_child(hint)

	_build_zone1_sky_constellation(zone_root.position, stick, marble)


func _build_zone1_sky_constellation(zone_pos: Vector3, stick: Node, marble: Material) -> void:
	## Sky board far ahead/above; locked cam looks up at ~45°.
	const PANEL_SIZE := 6.5
	const VIEW_DIST := 34.0
	## 45° elevation: equal rise and run from camera to board center.
	var elev := deg_to_rad(45.0)
	var cam_local := Vector3(0.0, -VIEW_DIST * sin(elev), -VIEW_DIST * cos(elev))

	## Float the constellation deep into the sky beyond Zone 1.
	var outward := zone_pos
	outward.y = 0.0
	if outward.length_squared() < 0.001:
		outward = Vector3(0.0, 0.0, 1.0)
	else:
		outward = outward.normalized()

	var sky := Node3D.new()
	sky.name = "Zone1SkyConstellation"
	sky.position = zone_pos + Vector3(0.0, 26.0, 0.0) + outward * 22.0
	sky.add_to_group("hermes_sky_constellation")
	## Face the approach (toward plaza / stick) so the 45° view reads naturally.
	var to_plaza := -outward
	sky.basis = Basis.looking_at(to_plaza, Vector3.UP)
	_mark(sky)

	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.72, 0.7, 0.66, 0.0)
	panel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel_mat.roughness = 0.9

	var panel := LineTracePanel.new()
	panel.name = "Zone1CompositePanel"
	## Local -Z faces the camera (Basis.looking_at points -Z at the cam).
	panel.setup(
		HermesPuzzleDataScript.make_z1_intro(),
		Vector3(PANEL_SIZE, PANEL_SIZE, 0.08),
		Vector3(0.0, 0.0, -1.0),
		panel_mat
	)
	panel.external_start_only = true
	panel.open_prompt = "Use the control stick"
	panel.position = Vector3.ZERO
	## Orient panel so its face looks down the 45° view toward the solve cam.
	panel.basis = Basis.looking_at(cam_local.normalized(), Vector3.UP)
	panel.set_solid_enabled(false)
	sky.add_child(panel)
	## Ink plane sits on the logical board; path uses no-depth-test so it reads on top of tiles.
	_hide_composite_panel_mesh(panel)

	var mount := Node3D.new()
	mount.name = "ScatterMount"
	mount.position = Vector3.ZERO
	mount.set_meta("anamorph_truth_rotation", Vector3.ZERO)
	sky.add_child(mount)

	var solve_anchor := Marker3D.new()
	solve_anchor.name = "SolveCamAnchor"
	solve_anchor.position = cam_local
	solve_anchor.basis = Basis.looking_at(-cam_local, Vector3.UP)
	sky.add_child(solve_anchor)

	_spawn_sky_fragments(panel, mount, cam_local, PANEL_SIZE, marble)

	mount.set_meta("anamorph_panel_id", panel.puzzle_id)
	## Slightly stronger start offset so the first view reads more broken.
	mount.rotation_degrees = Vector3(22.0, -34.0, 0.0)

	if stick.has_method("configure"):
		stick.call("configure", panel, mount, solve_anchor)

	var sky_label := Label3D.new()
	sky_label.name = "SkyLabel"
	sky_label.text = "Wind Sight"
	sky_label.font_size = 48
	sky_label.pixel_size = 0.028
	sky_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sky_label.position = Vector3(0.0, PANEL_SIZE * 0.65, 0.0)
	sky_label.modulate = Color(0.9, 0.85, 0.65, 0.85)
	sky.add_child(sky_label)


func _hide_composite_panel_mesh(panel: LineTracePanel) -> void:
	var mesh := panel.get_node_or_null("PanelMesh")
	if mesh is MeshInstance3D:
		(mesh as MeshInstance3D).visible = false
	for child in panel.get_children():
		if child is Label3D:
			(child as Label3D).visible = false
	var grid := panel.get_node_or_null("GridVisual")
	if grid is Node3D:
		(grid as Node3D).visible = false
		## Keep ink coplanar with the board face — offsetting toward the camera
		## breaks perspective and makes the path miss the fused tiles.
		(grid as Node3D).position = panel.face_normal * 0.04
	panel.set_meta("anamorph_composite", true)


func _spawn_sky_fragments(
	panel: LineTracePanel,
	mount: Node3D,
	cam_local: Vector3,
	panel_size: float,
	marble: Material
) -> void:
	## Strong anamorph: chips stay on solve-cam rays (so they fuse at truth) but with
	## scrambled depths, stretch, and twist so off-angles look sheared — not a neat lattice.
	var defs: LineTraceDefs = panel.defs
	if defs == null:
		return
	var gw: int = maxi(1, defs.grid_w)
	var gh: int = maxi(1, defs.grid_h)
	## Match LineTracePanel axes for face_normal (0,0,-1): u = -X, v = +Y.
	var face := Vector3(0.0, 0.0, -1.0)
	var u_axis := Vector3(-1.0, 0.0, 0.0)
	var v_axis := Vector3(0.0, 1.0, 0.0)
	var half := panel_size * 0.5
	var thickness := 0.08
	var face_lift := face * (thickness * 0.5 + 0.02)
	var cell_w := (panel_size * 0.92) / float(gw)
	var cell_h := (panel_size * 0.92) / float(gh)

	var base_col := Color(0.78, 0.76, 0.72)
	if marble is StandardMaterial3D:
		base_col = (marble as StandardMaterial3D).albedo_color

	var frag_root := Node3D.new()
	frag_root.name = "Fragments"
	mount.add_child(frag_root)

	## Panel may be rotated in sky space — express cell centers in sky/mount space.
	var panel_xf := panel.transform

	for y in gh:
		for x in gw:
			var cell := Vector2i(x, y)
			var u := ((float(x) + 0.5) / float(gw)) * 2.0 - 1.0
			var v := 1.0 - ((float(y) + 0.5) / float(gh)) * 2.0
			var on_panel_local: Vector3 = u_axis * (u * half * 0.92) + v_axis * (v * half * 0.92) + face_lift
			var on_panel: Vector3 = panel_xf * on_panel_local
			var dir := (on_panel - cam_local)
			var dist := dir.length()
			if dist < 0.001:
				continue
			dir /= dist

			## Deterministic scramble (not row-ordered) so neighbors don't form neat depth bands.
			var scramble := fposmod(float(x * 7 + y * 13) * 0.618034, 1.0)
			var scramble2 := fposmod(float(x * 3 + y * 11) * 0.381966, 1.0)
			## Wide depth range: near-cam → past the board plane.
			var depth := lerpf(dist * 0.26, dist * 1.18, scramble)
			var frag_pos := cam_local + dir * depth
			var scale := depth / dist

			## Mild per-tile stretch (heavy stretch breaks the fused board silhouette).
			var stretch_u := lerpf(0.82, 1.22, scramble)
			var stretch_v := lerpf(0.82, 1.22, scramble2)
			var twist := lerpf(-0.4, 0.4, fposmod(scramble + scramble2, 1.0))

			var frag := MeshInstance3D.new()
			frag.name = "Frag_%d_%d" % [x, y]
			var box := BoxMesh.new()
			box.size = Vector3(
				cell_w * scale * 0.88 * stretch_u,
				cell_h * scale * 0.88 * stretch_v,
				maxf(0.1, 0.16 * scale)
			)
			frag.mesh = box
			frag.position = frag_pos
			var face_basis := Basis.looking_at(cam_local - frag_pos, Vector3.UP)
			frag.basis = face_basis.rotated(face_basis.z.normalized(), twist)

			var mat := StandardMaterial3D.new()
			var col := base_col
			if defs.is_black(cell) or defs.is_blocked(cell):
				col = Color(0.14, 0.11, 0.09)
			elif defs.is_start(cell):
				col = Color(1.0, 0.82, 0.25)
			elif defs.is_exit(cell):
				col = Color(0.35, 0.85, 1.0)
			elif (x + y) % 2 == 0:
				col = base_col.darkened(0.12)
			else:
				col = base_col.lightened(0.05)
			mat.albedo_color = col
			mat.roughness = 0.82
			if defs.is_start(cell) or defs.is_exit(cell):
				mat.emission_enabled = true
				mat.emission = col
				mat.emission_energy_multiplier = 1.4
			frag.material_override = mat
			frag_root.add_child(frag)

			## Orange coal gem on black pieces (visible on the dark tile).
			if defs.is_black(cell):
				var coal := MeshInstance3D.new()
				coal.name = "CoalGem"
				var coal_box := BoxMesh.new()
				var gem := mini(cell_w, cell_h) * scale * 0.34
				coal_box.size = Vector3(gem, gem, maxf(0.06, 0.1 * scale))
				coal.mesh = coal_box
				## Frag -Z faces the camera after looking_at.
				coal.position = Vector3(0.0, 0.0, -maxf(0.05, 0.08 * scale))
				var coal_mat := StandardMaterial3D.new()
				coal_mat.albedo_color = Color(1.0, 0.42, 0.08)
				coal_mat.emission_enabled = true
				coal_mat.emission = Color(1.0, 0.4, 0.08)
				coal_mat.emission_energy_multiplier = 2.2
				coal_mat.roughness = 0.35
				coal.material_override = coal_mat
				frag.add_child(coal)


func _zone_rail_gap_yaws(zone_id: int, is_center: bool, pos: Vector3) -> Array[float]:
	## Yaws (rad) where bridges / stations meet the disc — leave open so you can walk on/off.
	var gaps: Array[float] = []
	if is_center:
		gaps.append(0.0) # spawn / north
		for deg in ZONE_ANGLES.values():
			gaps.append(deg_to_rad(float(deg)))
	else:
		# Opening toward the court center.
		var inward := Vector3(-pos.x, 0.0, -pos.z)
		if inward.length_squared() > 0.001:
			gaps.append(atan2(inward.x, inward.z))
	return gaps


func _yaw_near_gap(yaw: float, gaps: Array[float], half_gap: float) -> bool:
	for g in gaps:
		var d := absf(angle_difference(yaw, g))
		if d <= half_gap:
			return true
	return false


func _add_rail_ring(parent: StaticBody3D, radius: float, curb_mat: Material, gap_yaws: Array[float]) -> void:
	## Low solid curb + tall invisible wall; mouth width matches the bridge deck.
	var half_gap := deg_to_rad(_bridge_gap_half_deg(radius))
	var segments := 96
	for i in segments:
		var t0 := float(i) / float(segments)
		var t1 := float(i + 1) / float(segments)
		var yaw0 := t0 * TAU
		var yaw1 := t1 * TAU
		var yaw_mid := yaw0 + angle_difference(yaw0, yaw1) * 0.5
		if _yaw_near_gap(yaw_mid, gap_yaws, half_gap):
			continue

		var p0 := Vector3(sin(yaw0) * radius, 0.0, cos(yaw0) * radius)
		var p1 := Vector3(sin(yaw1) * radius, 0.0, cos(yaw1) * radius)
		var mid_xz := (p0 + p1) * 0.5
		var chord := p0.distance_to(p1)
		var yaw := atan2(p1.x - p0.x, p1.z - p0.z)
		_add_curb_and_barrier(
			parent,
			curb_mat,
			mid_xz,
			yaw,
			maxf(chord * 1.08, 0.12)
		)


func _add_curb_and_barrier(
	parent: StaticBody3D,
	curb_mat: Material,
	mid_xz: Vector3,
	yaw: float,
	length: float
) -> void:
	# Visible low solid curb.
	var curb := MeshInstance3D.new()
	var curb_mesh := BoxMesh.new()
	curb_mesh.size = Vector3(CURB_THICKNESS, CURB_HEIGHT, length)
	curb.mesh = curb_mesh
	curb.material_override = curb_mat
	curb.position = mid_xz + Vector3(0.0, CURB_HEIGHT * 0.5, 0.0)
	curb.rotation.y = yaw
	parent.add_child(curb)

	var curb_col := CollisionShape3D.new()
	var curb_box := BoxShape3D.new()
	curb_box.size = curb_mesh.size
	curb_col.shape = curb_box
	curb_col.position = curb.position
	curb_col.rotation.y = yaw
	parent.add_child(curb_col)

	# Invisible full-height barrier (blocks jumping the rim).
	var wall := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(BARRIER_THICKNESS, BARRIER_HEIGHT, length)
	wall.shape = wall_box
	wall.position = mid_xz + Vector3(0.0, BARRIER_HEIGHT * 0.5, 0.0)
	wall.rotation.y = yaw
	parent.add_child(wall)


func _bridge_gap_half_deg(radius: float) -> float:
	# Mouth matches deck; tiny pad so curb ends sit against bridge side rails.
	return rad_to_deg(atan((BRIDGE_WIDTH * 0.5) / maxf(radius, 0.5))) + 0.35


func _build_bridge_to_center(
	zone_id: int,
	outer_pos: Vector3,
	outer_r: float,
	center_r: float,
	center_y: float,
	marble: Material,
	curb_mat: Material
) -> void:
	var flat := Vector3(outer_pos.x, 0.0, outer_pos.z)
	if flat.length_squared() < 0.001:
		return
	var dir := flat.normalized() # center → outer
	var center_rim := dir * center_r
	var outer_rim := flat - dir * outer_r

	# Flat aprons sit on each plaza floor and cover the circle-vs-straight join.
	_build_junction_landing(
		"Landing_Zone%d_Center" % zone_id,
		center_rim,
		-dir,
		center_y,
		marble,
		curb_mat
	)
	_build_junction_landing(
		"Landing_Zone%d_Outer" % zone_id,
		outer_rim,
		dir,
		outer_pos.y,
		marble,
		curb_mat
	)

	# Sloped span only between rims — flush with each apron at the rim.
	var ramp_a := Vector3(center_rim.x, center_y, center_rim.z)
	var ramp_b := Vector3(outer_rim.x, outer_pos.y, outer_rim.z)
	_build_ramp_span("Bridge_Zone_%d" % zone_id, ramp_a, ramp_b, marble, curb_mat)


func _build_junction_landing(
	landing_name: String,
	rim: Vector3,
	into_zone: Vector3,
	floor_y: float,
	marble: Material,
	curb_mat: Material
) -> void:
	## Flat deck at `floor_y`: overlaps into the disc and slightly onto the bridge.
	var inward := Vector3(into_zone.x, 0.0, into_zone.z)
	if inward.length_squared() < 0.0001:
		return
	inward = inward.normalized()
	var outward := -inward

	var inner_pt := rim + inward * LANDING_INSET
	var outer_pt := rim + outward * LANDING_OVERLAP
	inner_pt.y = floor_y
	outer_pt.y = floor_y

	var mid := (inner_pt + outer_pt) * 0.5
	var depth := inner_pt.distance_to(outer_pt)
	var yaw := atan2(outward.x, outward.z)

	var body := StaticBody3D.new()
	body.name = landing_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = mid
	body.rotation.y = yaw

	var deck := MeshInstance3D.new()
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(BRIDGE_WIDTH, BRIDGE_DECK_THICKNESS, depth)
	deck.mesh = deck_mesh
	deck.material_override = marble
	deck.position = Vector3(0.0, -BRIDGE_DECK_THICKNESS * 0.5, 0.0)
	body.add_child(deck)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = deck_mesh.size
	shape.shape = box
	shape.position = deck.position
	body.add_child(shape)

	for side in [-1, 1]:
		var x := float(side) * (BRIDGE_WIDTH * 0.5 - CURB_THICKNESS * 0.5)
		_add_local_curb_barrier(body, curb_mat, x, depth)

	_mark(body)


func _add_local_curb_barrier(parent: StaticBody3D, curb_mat: Material, x: float, length: float) -> void:
	var curb := MeshInstance3D.new()
	var curb_mesh := BoxMesh.new()
	curb_mesh.size = Vector3(CURB_THICKNESS, CURB_HEIGHT, length)
	curb.mesh = curb_mesh
	curb.material_override = curb_mat
	curb.position = Vector3(x, CURB_HEIGHT * 0.5, 0.0)
	parent.add_child(curb)

	var curb_col := CollisionShape3D.new()
	var curb_box := BoxShape3D.new()
	curb_box.size = curb_mesh.size
	curb_col.shape = curb_box
	curb_col.position = curb.position
	parent.add_child(curb_col)

	var wall := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(BARRIER_THICKNESS, BARRIER_HEIGHT, length)
	wall.shape = wall_box
	wall.position = Vector3(x, BARRIER_HEIGHT * 0.5, 0.0)
	parent.add_child(wall)


func _build_ramp_span(bridge_name: String, start: Vector3, end: Vector3, marble: Material, curb_mat: Material) -> void:
	## Sloped deck whose top plane passes through `start` and `end` (zone floor heights at rims).
	var mid := (start + end) * 0.5
	var delta := end - start
	var length := delta.length()
	if length < 0.2:
		return

	var body := StaticBody3D.new()
	body.name = bridge_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.transform = Transform3D(Basis.looking_at(delta.normalized(), Vector3.UP), mid)

	var deck := MeshInstance3D.new()
	var deck_mesh := BoxMesh.new()
	# Slight extra length so ramp seats under both flat landings.
	deck_mesh.size = Vector3(BRIDGE_WIDTH, BRIDGE_DECK_THICKNESS, length + LANDING_OVERLAP * 2.0)
	deck.mesh = deck_mesh
	deck.material_override = marble
	deck.position = Vector3(0.0, -BRIDGE_DECK_THICKNESS * 0.5, 0.0)
	body.add_child(deck)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = deck_mesh.size
	shape.shape = box
	shape.position = deck.position
	body.add_child(shape)

	for side in [-1, 1]:
		var x := float(side) * (BRIDGE_WIDTH * 0.5 - CURB_THICKNESS * 0.5)
		_add_local_curb_barrier(body, curb_mat, x, length + LANDING_OVERLAP * 2.0)

	_mark(body)


func _build_spawn_approach(marble: Material, marble_dark: Material, gold: Material, curb_mat: Material) -> void:
	## Large north plaza + long bridge into Zone 5, with hub-return stele.
	var half_d := SPAWN_PAD_D * 0.5
	var spawn_z := ZONE5_RADIUS + SPAWN_BRIDGE_LENGTH + half_d
	var spawn_pos := Vector3(0.0, SPAWN_Y, spawn_z)

	var pad := StaticBody3D.new()
	pad.name = "SpawnPad"
	pad.collision_layer = 1
	pad.collision_mask = 0
	pad.position = spawn_pos

	var pad_mesh_i := MeshInstance3D.new()
	var pad_box := BoxMesh.new()
	pad_box.size = Vector3(SPAWN_PAD_W, PLATFORM_THICKNESS, SPAWN_PAD_D)
	pad_mesh_i.mesh = pad_box
	pad_mesh_i.material_override = marble
	pad_mesh_i.position = Vector3(0.0, -PLATFORM_THICKNESS * 0.5, 0.0)
	pad.add_child(pad_mesh_i)

	var pad_shape := CollisionShape3D.new()
	var pad_cs := BoxShape3D.new()
	pad_cs.size = pad_box.size
	pad_shape.shape = pad_cs
	pad_shape.position = pad_mesh_i.position
	pad.add_child(pad_shape)

	var emblem := MeshInstance3D.new()
	var emblem_mesh := BoxMesh.new()
	emblem_mesh.size = Vector3(3.2, 0.05, 1.2)
	emblem.mesh = emblem_mesh
	emblem.material_override = gold
	emblem.position = Vector3(0.0, 0.04, 0.4)
	pad.add_child(emblem)
	var emblem2 := MeshInstance3D.new()
	var emblem2_mesh := BoxMesh.new()
	emblem2_mesh.size = Vector3(1.2, 0.05, 2.6)
	emblem2.mesh = emblem2_mesh
	emblem2.material_override = gold
	emblem2.position = Vector3(0.0, 0.04, 0.4)
	pad.add_child(emblem2)

	_add_spawn_pad_rails(pad, curb_mat)

	var spawn_label := Label3D.new()
	spawn_label.text = "SPAWN IN"
	spawn_label.font_size = 42
	spawn_label.pixel_size = 0.012
	spawn_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spawn_label.position = Vector3(0.0, 2.6, 0.0)
	spawn_label.modulate = Color(0.95, 0.88, 0.55)
	pad.add_child(spawn_label)

	_mark(pad)

	var spawn_rim := Vector3(0.0, 0.0, spawn_z - half_d)
	var center_rim := Vector3(0.0, 0.0, ZONE5_RADIUS)
	_build_junction_landing("Landing_Spawn", spawn_rim, Vector3(0.0, 0.0, 1.0), SPAWN_Y, marble, curb_mat)
	_build_junction_landing("Landing_Spawn_Zone5", center_rim, Vector3(0.0, 0.0, -1.0), ZONE5_Y, marble, curb_mat)
	_build_ramp_span(
		"Bridge_Spawn",
		Vector3(center_rim.x, ZONE5_Y, center_rim.z),
		Vector3(spawn_rim.x, SPAWN_Y, spawn_rim.z),
		marble,
		curb_mat
	)

	_build_hub_return_stele(spawn_pos + Vector3(0.0, 0.0, half_d * 0.35), marble_dark, gold)


func _add_spawn_pad_rails(pad: StaticBody3D, curb_mat: Material) -> void:
	var half_w := SPAWN_PAD_W * 0.5
	var half_d := SPAWN_PAD_D * 0.5
	var mouth := BRIDGE_WIDTH * 0.5
	var walls: Array = [
		{"pos": Vector3(0.0, 0.0, half_d), "size_xz": Vector2(SPAWN_PAD_W, CURB_THICKNESS)},
		{"pos": Vector3(-half_w, 0.0, 0.0), "size_xz": Vector2(CURB_THICKNESS, SPAWN_PAD_D)},
		{"pos": Vector3(half_w, 0.0, 0.0), "size_xz": Vector2(CURB_THICKNESS, SPAWN_PAD_D)},
		{
			"pos": Vector3(-(half_w + mouth) * 0.5, 0.0, -half_d),
			"size_xz": Vector2(half_w - mouth, CURB_THICKNESS),
		},
		{
			"pos": Vector3((half_w + mouth) * 0.5, 0.0, -half_d),
			"size_xz": Vector2(half_w - mouth, CURB_THICKNESS),
		},
	]
	for w in walls:
		var size_xz: Vector2 = w["size_xz"]
		if size_xz.x < 0.15 or size_xz.y < 0.15:
			continue
		var mid: Vector3 = w["pos"]
		var curb := MeshInstance3D.new()
		var curb_mesh := BoxMesh.new()
		curb_mesh.size = Vector3(size_xz.x, CURB_HEIGHT, size_xz.y)
		curb.mesh = curb_mesh
		curb.material_override = curb_mat
		curb.position = mid + Vector3(0.0, CURB_HEIGHT * 0.5, 0.0)
		pad.add_child(curb)
		var curb_col := CollisionShape3D.new()
		var curb_box := BoxShape3D.new()
		curb_box.size = curb_mesh.size
		curb_col.shape = curb_box
		curb_col.position = curb.position
		pad.add_child(curb_col)
		var wall := CollisionShape3D.new()
		var wall_box := BoxShape3D.new()
		wall_box.size = Vector3(size_xz.x, BARRIER_HEIGHT, size_xz.y)
		wall.shape = wall_box
		wall.position = mid + Vector3(0.0, BARRIER_HEIGHT * 0.5, 0.0)
		pad.add_child(wall)


func _build_hub_return_stele(pos: Vector3, stone: Material, gold: Material) -> void:
	## Rising stele on the spawn pad — same pattern as hub shrine approaches.
	var portal := Area3D.new()
	portal.name = "ExitToHub"
	portal.collision_layer = 0
	portal.collision_mask = 2
	portal.monitoring = true
	portal.monitorable = false
	portal.position = pos
	portal.set_script(load("res://systems/rising_monument_portal.gd"))
	portal.set("destination_scene_id", "hub")
	portal.set("destination_spawn_id", "from_hermes")
	portal.set("require_unlocked", false)
	portal.set("open_prompt", "Press E — Return to Hub")
	portal.set("locked_prompt", "Return to Hub")
	portal.set("stele_height", 1.35)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.8, 2.2, 4.0)
	col.shape = box
	col.position = Vector3(0.0, 1.1, 0.1)
	portal.add_child(col)

	var pad_mesh := MeshInstance3D.new()
	pad_mesh.name = "PadMesh"
	var pad_box := BoxMesh.new()
	pad_box.size = Vector3(2.6, 0.05, 2.2)
	pad_mesh.mesh = pad_box
	pad_mesh.material_override = gold
	pad_mesh.position = Vector3(0.0, 0.03, 1.0)
	portal.add_child(pad_mesh)

	var stele := StaticBody3D.new()
	stele.name = "Stele"
	stele.collision_layer = 0
	stele.collision_mask = 0
	stele.position = Vector3(0.0, -1.31, -0.85)
	stele.set_script(load("res://systems/stele_interact.gd"))

	var stele_mesh := MeshInstance3D.new()
	stele_mesh.name = "MeshInstance3D"
	var stele_box := BoxMesh.new()
	stele_box.size = Vector3(1.15, 1.35, 0.3)
	stele_mesh.mesh = stele_box
	stele_mesh.material_override = stone
	stele_mesh.position = Vector3(0.0, 0.675, 0.0)
	stele.add_child(stele_mesh)

	var stele_col := CollisionShape3D.new()
	var stele_shape := BoxShape3D.new()
	stele_shape.size = Vector3(1.25, 1.35, 0.38)
	stele_col.shape = stele_shape
	stele_col.position = Vector3(0.0, 0.675, 0.0)
	stele.add_child(stele_col)

	var label := Label3D.new()
	label.name = "Label3D"
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0.0, 1.55, 0.2)
	label.font_size = 28
	label.outline_size = 6
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.visible = false
	stele.add_child(label)

	portal.add_child(stele)
	_mark(portal)
