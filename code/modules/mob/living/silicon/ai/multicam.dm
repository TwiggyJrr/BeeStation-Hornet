//Picture in picture

/atom/movable/screen/movable/pic_in_pic/ai
	var/mob/living/silicon/ai/ai
	var/mutable_appearance/highlighted_background
	var/highlighted = FALSE
	var/mob/camera/ai_eye/pic_in_pic/ai_eye

/atom/movable/screen/movable/pic_in_pic/ai/Initialize(mapload)
	. = ..()
	ai_eye = new /mob/camera/ai_eye/pic_in_pic()
	ai_eye.screen = src

/atom/movable/screen/movable/pic_in_pic/ai/Destroy()
	ai_eye.transfer_observers_to(ai.eyeobj) // secondary ai eye to main one
	set_ai(null)
	QDEL_NULL(ai_eye)
	return ..()

/atom/movable/screen/movable/pic_in_pic/ai/Click()
	..()
	if(ai)
		ai.select_main_multicam_window(src)

/atom/movable/screen/movable/pic_in_pic/ai/make_backgrounds()
	..()
	highlighted_background = new /mutable_appearance()
	highlighted_background.icon = 'icons/misc/pic_in_pic.dmi'
	highlighted_background.icon_state = "background_highlight"
	highlighted_background.layer = SPACE_LAYER

/atom/movable/screen/movable/pic_in_pic/ai/add_background()
	if((width > 0) && (height > 0))
		var/matrix/M = matrix()
		M.Scale(width + 0.5, height + 0.5)
		M.Translate((width-1)/2 * world.icon_size, (height-1)/2 * world.icon_size)
		highlighted_background.transform = M
		standard_background.transform = M
		add_overlay(highlighted ? highlighted_background : standard_background)

/atom/movable/screen/movable/pic_in_pic/ai/set_view_size(width, height, do_refresh = TRUE)
	ai_eye.static_visibility_range =	(round(max(width, height) / 2) + 1)
	if(ai)
		ai.camera_visibility(ai_eye)
	..()

/atom/movable/screen/movable/pic_in_pic/ai/set_view_center(atom/target, do_refresh = TRUE)
	..()
	ai_eye.setLoc(get_turf(target))

/atom/movable/screen/movable/pic_in_pic/ai/refresh_view()
	..()
	ai_eye.setLoc(get_turf(center))

/atom/movable/screen/movable/pic_in_pic/ai/proc/highlight()
	if(highlighted)
		return
	highlighted = TRUE
	cut_overlay(standard_background)
	add_overlay(highlighted_background)

/atom/movable/screen/movable/pic_in_pic/ai/proc/unhighlight()
	if(!highlighted)
		return
	highlighted = FALSE
	cut_overlay(highlighted_background)
	add_overlay(standard_background)

/atom/movable/screen/movable/pic_in_pic/ai/proc/set_ai(mob/living/silicon/ai/new_ai)
	if(ai)
		ai.multicam_screens -= src
		ai.all_eyes -= ai_eye
		if(ai.master_multicam == src)
			ai.master_multicam = null
		if(ai.multicam_on)
			unshow_to(ai.client)
	ai = new_ai
	if(new_ai)
		new_ai.multicam_screens += src
		ai.all_eyes += ai_eye
		if(new_ai.multicam_on)
			show_to(new_ai.client)

//Turf, area, and landmark for the viewing room

/turf/open/ai_visible
	name = ""
	icon = 'icons/misc/pic_in_pic.dmi'
	icon_state = "room_background"
	flags_1 = NOJAUNT_1

/area/ai_multicam_room
	name = "ai_multicam_room"
	icon_state = "ai_camera_room"
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	ambientsounds = list()
	area_flags = HIDDEN_AREA | UNIQUE_AREA
	teleport_restriction = TELEPORT_ALLOW_NONE

GLOBAL_DATUM(ai_camera_room_landmark, /obj/effect/landmark/ai_multicam_room)

/obj/effect/landmark/ai_multicam_room
	name = "ai camera room"
	icon = 'icons/mob/landmarks.dmi'
	icon_state = "x"

/obj/effect/landmark/ai_multicam_room/Initialize(mapload)
	. = ..()
	qdel(GLOB.ai_camera_room_landmark)
	GLOB.ai_camera_room_landmark = src

/obj/effect/landmark/ai_multicam_room/Destroy()
	if(GLOB.ai_camera_room_landmark == src)
		GLOB.ai_camera_room_landmark = null
	return ..()

//Dummy camera eyes

/mob/camera/ai_eye/pic_in_pic
	name = "Secondary AI Eye"
	invisibility = INVISIBILITY_OBSERVER
	mouse_opacity = MOUSE_OPACITY_ICON
	icon_state = "ai_pip_camera"
	var/atom/movable/screen/movable/pic_in_pic/ai/screen
	var/list/cameras_telegraphed = list()
	var/telegraph_cameras = TRUE
	var/telegraph_range = 7
	ai_detector_color = COLOR_ORANGE

/mob/camera/ai_eye/pic_in_pic/GetViewerClient()
	if(screen?.ai)
		return screen.ai.client

/mob/camera/ai_eye/pic_in_pic/setLoc(turf/destination)
	if (destination)
		abstract_move(destination)
	else
		moveToNullspace()
	if(screen && screen.ai)
		screen.ai.camera_visibility(src)
	else
		GLOB.cameranet.visibility(src)
	update_camera_telegraphing()
	update_ai_detect_hud()

/mob/camera/ai_eye/pic_in_pic/get_visible_turfs()
	return screen ? screen.get_visible_turfs() : list()

/mob/camera/ai_eye/pic_in_pic/proc/update_camera_telegraphing()
	if(!telegraph_cameras)
		return
	var/list/obj/machinery/camera/add = list()
	var/list/obj/machinery/camera/remove = list()
	var/list/obj/machinery/camera/visible = list()
	for (var/VV in visibleCameraChunks)
		var/datum/camerachunk/CC = VV
		for (var/V in CC.cameras)
			var/obj/machinery/camera/C = V
			if (!C.can_use() || (get_dist(C, src) > telegraph_range))
				continue
			visible |= C

	add = visible - cameras_telegraphed
	remove = cameras_telegraphed - visible

	for (var/V in remove)
		var/obj/machinery/camera/C = V
		if(QDELETED(C))
			continue
		cameras_telegraphed -= C
		C.in_use_lights--
		C.update_icon()
	for (var/V in add)
		var/obj/machinery/camera/C = V
		if(QDELETED(C))
			continue
		cameras_telegraphed |= C
		C.in_use_lights++
		C.update_icon()

/mob/camera/ai_eye/pic_in_pic/proc/disable_camera_telegraphing()
	telegraph_cameras = FALSE
	for (var/V in cameras_telegraphed)
		var/obj/machinery/camera/C = V
		if(QDELETED(C))
			continue
		C.in_use_lights--
		C.update_icon()
	cameras_telegraphed.Cut()

/mob/camera/ai_eye/pic_in_pic/Destroy()
	disable_camera_telegraphing()
	return ..()

//AI procs

/mob/living/silicon/ai/proc/drop_new_multicam(silent = FALSE)
	if(!CONFIG_GET(flag/allow_ai_multicam))
		if(!silent)
			to_chat(src, span_warning("This action is currently disabled. Contact an administrator to enable this feature."))
		return
	if(!eyeobj)
		return
	if(multicam_screens.len >= max_multicams)
		if(!silent)
			to_chat(src, span_warning("Cannot place more than [max_multicams] multicamera windows."))
		return
	var/atom/movable/screen/movable/pic_in_pic/ai/C = new /atom/movable/screen/movable/pic_in_pic/ai()
	C.set_view_size(3, 3, FALSE)
	C.set_view_center(get_turf(eyeobj))
	C.set_ai(src)
	if(!silent)
		to_chat(src, span_notice("Added new multicamera window."))
	if(multicam_on)
		reveal_eyemob(C.ai_eye)
	else
		hide_eyemob(C.ai_eye)
	return C

/mob/living/silicon/ai/proc/toggle_multicam()
	if(!CONFIG_GET(flag/allow_ai_multicam))
		to_chat(src, span_warning("This action is currently disabled. Contact an administrator to enable this feature."))
		return
	if(multicam_on)
		end_multicam()
	else
		start_multicam()

/mob/living/silicon/ai/proc/start_multicam()
	if(multicam_on || aiRestorePowerRoutine || !isturf(loc))
		return
	if(!GLOB.ai_camera_room_landmark)
		to_chat(src, span_warning("This function is not available at this time."))
		return
	multicam_on = TRUE
	refresh_multicam()
	refresh_camera_obj_visibility()
	to_chat(src, span_notice("Multiple-camera viewing mode activated."))

/mob/living/silicon/ai/proc/refresh_multicam()
	reset_perspective(GLOB.ai_camera_room_landmark)
	if(client)
		for(var/V in multicam_screens)
			var/atom/movable/screen/movable/pic_in_pic/P = V
			P.show_to(client)

/mob/living/silicon/ai/proc/end_multicam()
	if(!multicam_on)
		return
	multicam_on = FALSE
	refresh_camera_obj_visibility()
	select_main_multicam_window(null)
	if(client)
		for(var/V in multicam_screens)
			var/atom/movable/screen/movable/pic_in_pic/P = V
			P.unshow_to(client)
	reset_perspective()
	to_chat(src, span_notice("Multiple-camera viewing mode deactivated."))

/mob/living/silicon/ai/proc/refresh_camera_obj_visibility()
	for(var/V in multicam_screens)
		var/atom/movable/screen/movable/pic_in_pic/ai/each_screen = V
		if(!istype(each_screen) || !each_screen.ai_eye)
			continue
		if(multicam_on)
			reveal_eyemob(each_screen.ai_eye)
		else
			hide_eyemob(each_screen.ai_eye)

/mob/living/silicon/ai/proc/reveal_eyemob(mob/camera/ai_eye/target_eye)
	target_eye.invisibility = INVISIBILITY_OBSERVER
	target_eye.ai_detector_visible = TRUE
	target_eye.update_ai_detect_hud()

// we don't want to see inactive eye mobs
/mob/living/silicon/ai/proc/hide_eyemob(mob/camera/ai_eye/target_eye)
	target_eye.invisibility = INVISIBILITY_ABSTRACT
	target_eye.ai_detector_visible = FALSE
	target_eye.update_ai_detect_hud()
	if(eyeobj) // if ghosts are orbiting secondary ai eye, transfer them to the main eye
		target_eye.transfer_observers_to(eyeobj)

/mob/living/silicon/ai/proc/select_main_multicam_window(atom/movable/screen/movable/pic_in_pic/ai/P)
	if(master_multicam == P)
		return

	if(master_multicam)
		master_multicam.set_view_center(get_turf(eyeobj), FALSE)
		master_multicam.unhighlight()
		master_multicam = null

	if(P)
		P.highlight()
		eyeobj.setLoc(get_turf(P.center))
		P.set_view_center(eyeobj)
		master_multicam = P
