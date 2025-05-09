/obj/machinery/gulag_item_reclaimer
	name = "equipment reclaimer station"
	desc = "Used to reclaim your items after you finish your sentence at the labor camp."
	icon = 'icons/obj/terminals.dmi'
	icon_state = "dorm_taken"
	req_access = list(ACCESS_SECURITY) //REQACCESS TO ACCESS ALL STORED ITEMS
	density = FALSE
	use_power = IDLE_POWER_USE
	idle_power_usage = 100
	active_power_usage = 2500
	var/list/stored_items = list()
	var/obj/machinery/gulag_teleporter/linked_teleporter

/obj/machinery/gulag_item_reclaimer/Destroy()
	for(var/i in contents)
		var/obj/item/I = i
		I.forceMove(get_turf(src))
	if(linked_teleporter)
		linked_teleporter.linked_reclaimer = null
	return ..()

/obj/machinery/gulag_item_reclaimer/on_emag(mob/user)
	..()
	// emagging lets anyone reclaim all the items
	req_access = list()
	ui_update()

/obj/machinery/gulag_item_reclaimer/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/gulag_item_reclaimer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GulagItemReclaimer")
		ui.open()

/obj/machinery/gulag_item_reclaimer/ui_data(mob/user)
	var/list/data = list()
	var/can_reclaim = FALSE

	if(allowed(user))
		can_reclaim = TRUE

	var/obj/item/card/id/I = user.get_idcard(TRUE)
	if(istype(I, /obj/item/card/id/gulag))
		var/obj/item/card/id/gulag/prisonerID = I
		if(prisonerID.points >= prisonerID.goal && !prisonerID.permanent)
			can_reclaim = TRUE

	var/list/mobs = list()
	for(var/i in stored_items)
		var/mob/thismob = i
		if(QDELETED(thismob))
			say("Alert! Unable to locate vital signals of a previously processed prisoner. Ejecting equipment!")
			drop_items(thismob)
			continue
		var/list/mob_info = list()
		mob_info["name"] = thismob.real_name
		mob_info["mob"] = "[REF(thismob)]"
		mobs += list(mob_info)

	data["mobs"] = mobs
	data["can_reclaim"] = can_reclaim

	return data

/obj/machinery/gulag_item_reclaimer/ui_act(action, params)
	if(..())
		return

	switch(action)
		if("release_items")
			var/mob/living/carbon/human/H = locate(params["mobref"]) in stored_items
			if(H != usr && !allowed(usr))
				to_chat(usr, span_warning("Access denied."))
				return
			drop_items(H)
			. = TRUE

/obj/machinery/gulag_item_reclaimer/proc/drop_items(mob/user)
	if(!stored_items[user])
		return
	var/drop_location = drop_location()
	for(var/i in stored_items[user])
		var/obj/item/W = i
		stored_items[user] -= W
		W.forceMove(drop_location)
	stored_items -= user
