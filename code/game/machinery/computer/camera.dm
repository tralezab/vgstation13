//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

var/global/list/tv_monitors = list()

/obj/machinery/computer/security
	name = "Security Cameras"
	desc = "Used to access the various cameras on the station."
	icon_state = "cameras"
	circuit = "/obj/item/weapon/circuitboard/security"
	var/obj/machinery/camera/current = null
	var/last_pic = 1.0
	var/list/network = list(CAMERANET_SS13)
	var/mapping = 0//For the overview file, interesting bit of code.

	var/current_net

	var/list/datum/action/camera/our_actions = list()
	var/static/list/obj/machinery/camera/sorted_cams = list(
	)
	var/static/list/obj/machinery/camera/deactivated_cams = list(
	)
	var/list/obj/machinery/camera/cyborg_cams = list(
		CAMERANET_ROBOTS = list(), // Borgos
		CAMERANET_ENGI	 = list(), // Mommers
	)

	light_color = LIGHT_COLOR_RED

/obj/machinery/computer/security/New()
	..()
	var/datum/action/camera/previous/P = new(src)
	var/datum/action/camera/cancel/C = new(src)
	var/datum/action/camera/cyborg/C1 = new(src)
	var/datum/action/camera/listing/L = new(src)
	var/datum/action/camera/next/N = new(src)
	our_actions = list(P, C, C1, L, N)

	if (ticker && ticker.current_state  == GAME_STATE_PLAYING)
		init_cams()

	tv_monitors += src

/obj/machinery/computer/security/proc/init_cams()
	for (var/network in sorted_cams)
		if (!(network in src.network))
			continue
		current_net = network
		var/list/net = sorted_cams[network]
		if (net.len)
			current = net[1]
			break

/obj/machinery/computer/security/Destroy()
	tv_monitors -= src
	our_actions.Cut() // removes our actions
	..()

/obj/machinery/computer/security/attack_ai(var/mob/user)
	src.add_hiddenprint(user)
	return attack_hand(user)


/obj/machinery/computer/security/attack_paw(var/mob/user)
	return attack_hand(user)


/obj/machinery/computer/security/check_eye(var/mob/user)
	if ((!Adjacent(user) || user.isStunned() || user.blinded || !( current ) || !( current.status )) && (!istype(user, /mob/living/silicon)))
		user.cancel_camera()
		return null
	user.reset_view(current)
	return 1


/obj/machinery/computer/security/attack_hand(var/mob/user)

	if (src.z > 6)
		to_chat(user, "<span class='danger'>Unable to establish a connection: </span>You're too far away from the station!")
		return
	if(stat & (NOPOWER|BROKEN))
		return

	if(!isAI(user))
		user.set_machine(src)

	for (var/datum/action/camera/action in our_actions)
		if (action.owner && action.owner != user)
			action.owner.cancel_camera()
		action.Grant(user)

/obj/machinery/computer/security/telescreen
	name = "Telescreen"
	desc = "Used for watching arena fights and variety shows."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "telescreen"
	network = list(CAMERANET_THUNDER)
	density = 0
	circuit = null

	light_color = null

/obj/machinery/computer/security/telescreen/examine(mob/user)
	..()
	to_chat(user, "Looks like the current channel is \"<span class='info'>[current.c_tag]</span>\"")

/obj/machinery/computer/security/telescreen/update_icon()
	icon_state = initial(icon_state)
	if(stat & BROKEN)
		icon_state += "b"
	return

/obj/machinery/computer/security/telescreen/entertainment
	name = "entertainment monitor"
	desc = "Damn, they better have chicken-channel on these things."
	icon = 'icons/obj/status_display.dmi'
	icon_state = "entertainment"
	network = list(CAMERANET_THUNDER, CAMERANET_COURTROOM)
	density = 0
	circuit = null

	light_color = null

/obj/machinery/computer/security/wooden_tv
	name = "Security Cameras"
	desc = "An old TV hooked into the stations camera network."
	icon_state = "security_det"

	light_color = null

/obj/machinery/computer/security/mining
	name = "Outpost Cameras"
	desc = "Used to access the various cameras on the outpost."
	icon_state = "miningcameras"
	network = list(CAMERANET_MINE)
	circuit = "/obj/item/weapon/circuitboard/mining"

	light_color = LIGHT_COLOR_PINK

/obj/machinery/computer/security/proc/set_camera(var/mob/living/user, var/obj/machinery/camera/C)
	if(C)
		if ((!Adjacent(user) || user.machine != src || user.blinded || user.isStunned() || !( C.can_use() )) && (!istype(user, /mob/living/silicon/ai)))
			if(!C.can_use() && !isAI(user))
				src.current = null
			user.cancel_camera()
			return 0
		else
			if(isAI(user))
				var/mob/living/silicon/ai/A = user
				A.eyeobj.forceMove(get_turf(C))
				A.client.eye = A.eyeobj
			else
				src.current = C
				use_power(50)

	user.set_machine(src)
	user.reset_view(current)

/obj/machinery/computer/security/proc/get_cameras()

	for (var/obj/machinery/camera/C in cameranet.cameras)
		for (var/net in C.network)
			if (!(net in sorted_cams))
				sorted_cams[net] = list()
			sorted_cams[net] += C

	for (var/net in sorted_cams)
		var/list/that_network = sorted_cams[net]
		that_network = camera_sort(that_network)

/obj/machinery/computer/security/proc/next(var/mob/living/user)

	if (!current_net)
		user.cancel_camera()
		return FALSE

	var/list/net = sorted_cams[current_net]

	var/place = net.Find(current)

	place++
	if (place > net.len)
		place = 1
		var/index = network.Find(current_net)
		var/stop = FALSE
		while (!stop)
			index++
			if (index > network.len)
				index = 1
			current = network[index]
			net = sorted_cams[current_net]
			if (length(net)) // if this is not an empty network...
				stop = TRUE

	var/obj/machinery/camera/C = net[place]

	set_camera(user, C)

/obj/machinery/computer/security/proc/previous(var/mob/living/user)

	if (!current_net)
		user.cancel_camera()
		return FALSE

	var/list/net = sorted_cams[current_net]

	var/place = net.Find(current)

	place--
	if (place <= 0)
		var/index = network.Find(current_net)
		var/stop = FALSE
		while (!stop)
			index--
			if (index <= 0)
				index = network.len
			current_net = network[index]
			net = sorted_cams[current_net]
			place = sorted_cams[current_net].len
			if (length(net)) // if this is not an empty network...
				stop = TRUE

	var/obj/machinery/camera/C = net[place]

	set_camera(user, C)

// -- Unlike security cameras (which are activated by default), Engineering cameras are dynamic.
// They add & remove themselves from the list as power alarms go.

/obj/machinery/computer/security/engineering
	name = "Engineering Cameras"
	desc = "Used to monitor engineering silicons and alarms."
	icon_state = "engineeringcameras"
	network = list(CAMERANET_ENGI,CAMERANET_POWERALARMS,CAMERANET_ATMOSALARMS,CAMERANET_FIREALARMS)
	circuit = "/obj/item/weapon/circuitboard/security/engineering"

	light_color = LIGHT_COLOR_YELLOW
	var/static/sorted = FALSE

// -- So what's going on here ?
// If it's not sorted, we sort the cameras in POWERALARMS and the rest
// Then, we look for an active cam ; if we don't have any we display an error message:

/obj/machinery/computer/security/engineering/attack_hand(var/mob/user)
	if (!sorted)
		get_cameras()
		init_cams()
		sorted = TRUE
	if (current)
		return ..()
	to_chat(user, "<span class='warning'>No active cameras found.</span>")

/obj/machinery/computer/security/engineering/init_cams()
	for (var/net in network)
		if (length(sorted_cams[net]))
			current_net = net
			var/list/L = sorted_cams[net]
			current = L[1]
			break

/obj/machinery/computer/security/engineering/get_cameras()
	for (var/net in network)
		var/list/cameras_to_sort = sorted_cams[net]
		if (length(cameras_to_sort))
			cameras_to_sort = camera_sort(cameras_to_sort)
	init_cams() // Sorting cameras means that we either added or removed a camera, which means that we should reinitialise the cameras


// Action buttons for camera cyclin

/datum/action/camera
	var/obj/machinery/computer/security/our_computer
	check_flags = AB_CHECK_RESTRAINED | AB_CHECK_STUNNED | AB_CHECK_LYING | AB_CHECK_CONSCIOUS

/datum/action/camera/New(var/obj/machinery/computer/security/our_computer)
	. =..()
	src.our_computer = our_computer

/datum/action/camera/next
	name = "Next camera"
	desc = "Cycle to the next camera in the camera net."
	icon_icon = 'icons/obj/camera_buttons.dmi'
	button_icon_state = "next"

/datum/action/camera/next/Trigger()
	our_computer.next(owner)

/datum/action/camera/previous
	name = "Previous camera"
	desc = "Cycle to the previous camera in the camera net."
	icon_icon = 'icons/obj/camera_buttons.dmi'
	button_icon_state = "previous"

/datum/action/camera/previous/Trigger()
	our_computer.previous(owner)

/datum/action/camera/listing
	name = "Camera listing"
	desc = "List all the cameras in the net, then let you choose between them."
	icon_icon = 'icons/obj/camera_buttons.dmi'
	button_icon_state = "listing"

/datum/action/camera/listing/Trigger()
	var/mob/living/user = owner
	if(!isAI(user))
		user.set_machine(our_computer)

	if (!cameranet.sorted)
		cameranet.cameras = camera_sort(cameranet.cameras)

	var/list/D = list()

	for(var/obj/machinery/camera/C in cameranet.cameras)
		if(!istype(C.network, /list))
			var/turf/T = get_turf(C)
			WARNING("[C] - Camera at ([T.x],[T.y],[T.z]) has a non list for network, [C.network]")
			C.network = list(C.network)
		var/list/tempnetwork = C.network & our_computer.network
		if(tempnetwork.len)
			D[text("[][]", C.c_tag, (C.status ? null : " (Deactivated)"))] = C

	var/t = input(user, "Which camera should you change to?") as null|anything in D
	if(!t)
		user.cancel_camera()
		return 0
	user.set_machine(our_computer)

	var/obj/machinery/camera/C = D[t]

	our_computer.set_camera(user, C)

/datum/action/camera/cancel
	name = "Cancel camera view"
	desc = "Cancels the camera view."
	icon_icon = 'icons/obj/camera_buttons.dmi'
	button_icon_state = "cancel"

/datum/action/camera/cancel/Trigger()
	var/mob/living/user = owner
	user.cancel_camera()

/datum/action/camera/cyborg
	name = "Cyborg camera listing"
	desc = "List all the cyborg cameras conected to this network."
	icon_icon = 'icons/obj/camera_buttons.dmi'
	button_icon_state = "robot"

/datum/action/camera/cyborg/Trigger()
	var/mob/living/user = owner
	if(!isAI(user))
		user.set_machine(our_computer)

	var/list/L = list()

	for (var/net in our_computer.cyborg_cams)
		for(var/obj/machinery/camera/C in our_computer.cyborg_cams[net])
			var/list/temp_network = (C.network & our_computer.network)
			if (temp_network.len)
				L[text("[][]", C.c_tag, (C.status ? null : " (Deactivated)"))] = C

	if (!L.len)
		to_chat(user, "<span class='warning'>No robots connected.</span>")

	var/t = input(user, "Which camera should you change to?") as null|anything in L
	if(!t || t == "Cancel")
		user.cancel_camera()
		return 0
	user.set_machine(our_computer)

	var/obj/machinery/camera/C = L[t]

	our_computer.set_camera(user, C)