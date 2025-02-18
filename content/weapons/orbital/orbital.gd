extends Node2D

var showcaseMode := false

var laser: Laser

var move: Vector2
var currentSpeed := 0.0
var distanceMoved := 0.0
var acceleration := 0.0

var pathProbe

var inputReady := false
var firing := false
var cooldown: float
var hitState := 1

const LASER_MAX_LENGTH = 600.0
var raycasts: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	Style.init(self)
	raycasts = [$RayCast2D, $RayCastL1, $RayCastR1, $RayCastL2, $RayCastR2, $RayCastL3, $RayCastR3]
	for r in raycasts:
		r.enabled = false
	$RayCast2D.enabled = true

func init(cupulaPath:Path2D):
	pathProbe = cupulaPath.createPathProbe(self)
	
	Style.init(self)

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"orbitallaser.width":
			for r in range(newValue*2 + 1):
				raycasts[r].enabled = true


func inputs(moveValue:Vector2, fireValue:float, specialValue:float):
	if GameWorld.paused or not inputReady:
		return

	if Options.useMouseDomeGameplay and not Options.useGamepad and not showcaseMode:
		var ms = get_global_mouse_position()
		#if inverse:
		#	ms.x = - ms.x
		var aimVector:Vector2 = ms - global_position
		var angleDiff = aimVector.angle() - (rotation - CONST.PI_HALF)
		if angleDiff > PI:
			angleDiff -= 2 * PI
		elif angleDiff < -PI:
			angleDiff += 2 * PI

		if aimVector.x < 0 and angleDiff > CONST.PI_HALF:
			angleDiff -= 2 * PI
		elif aimVector.x > 0 and angleDiff < - CONST.PI_HALF:
			angleDiff += 2 * PI

		var newMove = clamp(angleDiff * 4, -1, 1)
		if newMove != 0 and sign(newMove) != sign(move.x):
			# avoid oscillating and overshooting
			currentSpeed = 0
		move.x = newMove
	else:
		#if inverse:
			#moveValue.x = -moveValue.x
		move.x = moveValue.x

	if GameWorld.paused or not inputReady:
		return

	if fireValue > 0.0:
		# Start firing laser beam
		if not firing:
			firing = true
			laser.start()
			laser.set_endpoint(Vector2.ZERO)
			laser.stop_hit()
			#if SpriteCannon.animation.begins_with("idle"):
			#	setFrame(FRAME_SHOOT_START + fmod(frame, FRAME_MOVE_START))
			#SpriteCannon.play("shoot_" + str(variant))
#			if Data.of("laser.aimLine"):
#				$AimLine.visible = false
	else:
		stopFiring()
		#if SpriteCannon.animation.begins_with("shoot"):
		#	setFrame(FRAME_MOVE_START + fmod(frame, FRAME_SHOOT_START))
		#SpriteCannon.play("idle_" + str(variant))

func _physics_process(delta):
	if GameWorld.paused or not inputReady:
		return
	
	var laserMoveSpeed = Data.of("laser.movespeed") * Data.of("laser.movespeedmod")
	if move.x == 0:
		distanceMoved = 0
		$MoveSound.stop()
		currentSpeed = 0
		acceleration = 0
#		acceleration = clamp(acceleration + (10.0 - 12.0 * laserMoveSpeed) * delta, 0.0, 1.0)
	else:
#			distanceMoved -= 0.05
		if not $MoveSound.playing:
			$MoveSound.play()
		acceleration = clamp(acceleration + (10.0 - 13.0 * laserMoveSpeed) * delta, 0.0, 1.0)
	
	var goalSpeed = laserMoveSpeed * move.x

	if firing: 
		goalSpeed *= Data.of("laser.movespeedwhilefiring")
	if Options.useGamepad:
		currentSpeed = goalSpeed
	else:
		currentSpeed += (goalSpeed - currentSpeed) * delta * 8.0 * acceleration
	$MoveSound.pitch_scale = 0.45 + abs(currentSpeed) * 0.5
	var thisMove:float = pathProbe.moveBy(currentSpeed * delta)
	distanceMoved += abs(thisMove)

	var c
	var collisionPoint:Vector2
	var laserEndPos := Vector2(0,-1) * LASER_MAX_LENGTH
	var angleDelta := 0.0
	for raycast in raycasts:
		if not raycast.enabled:
			continue
		var c2 = raycast.get_collider()
		if c2:
			c = c2
			collisionPoint = raycast.get_collision_point()
			angleDelta = (collisionPoint - $RayCast2D.global_position).angle() - rotation + CONST.PI_HALF
			if angleDelta > PI:
				angleDelta -= 2*PI
			elif angleDelta < -PI:
				angleDelta += 2*PI
			laserEndPos = Vector2(0,-1) * ((collisionPoint - global_position).length() + 5)
			break
	
	if laser and Data.of("laser.aimLine"):
		$AimLine.visible = not firing
		if c and c.is_in_group("monster"):
			c.aim()
		$AimLine.set_point_position(1, laserEndPos)
	
	if firing:
		if c:
			if c.is_in_group("monster"):
				# Laser is hitting a monster
				laser.rotation += (angleDelta - laser.rotation) * delta * 5.0
				laser.target(laserEndPos)
				laser.start_hit(laserEndPos)
				if c.currentHealth >= 5:
					laser.playHitBumpSound()
				var damage = Data.of("laser.dps") * Data.of("laser.dpsmod") * delta
				c.hit("laser", damage, Data.of("laser.stun"))
#				if c.currentHealth - damage <= 0.0:
#					var e = preload("res://content/shared/explosions/Explosion3.tscn").instance()
#					e.damage = Data.of("laser.explode")
#					e.position = c.position
#					c.get_parent().add_child(e)
				hitState = 1
			elif Data.of("laser.hitprojectiles") and c.is_in_group("projectile"):
				c.domeAbsorbsDamage()
		elif hitState >= 1:
			hitState -= 1
		elif hitState == 0:
			laser.rotation = 0
			hitState = -1
			# Laser is not hitting anything
			laser.stop_hit()
			$AimLine.set_point_position(1, Vector2(0,-1) * LASER_MAX_LENGTH)
			laserEndPos = Vector2(0,-1) * LASER_MAX_LENGTH
			laser.target(laserEndPos)
	
	# Show or hide laser beam depending on if we're firing
	if firing:
		laser.visible = true


# Stop firing and show particles
func stopFiring():
	if firing:
		laser.stop()
		var end = (laser.get_endpoint() - laser.position).length()
		var amount = round(75 * (end/300.0))
		if amount > 0:
			var particles = preload("res://content/weapons/laser/RayParticles.tscn").instantiate()
			particles.process_material.emission_box_extents.y = end * 0.5
			particles.position.y = -0.5 * end
			particles.amount = amount
			add_child(particles)
		if Data.of("laser.aimLine"):
			$AimLine.visible = true
		hitState = 0
	firing = false
