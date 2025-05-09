
/turf/open/floor/engine
	name = "reinforced floor"
	desc = "Extremely sturdy."
	icon_state = "engine"
	holodeck_compatible = TRUE
	thermal_conductivity = 0.01
	heat_capacity = INFINITY
	floor_tile = /obj/item/stack/sheet/iron
	footstep = FOOTSTEP_PLATING
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	tiled_dirt = FALSE
	FASTDMM_PROP(\
		pipe_astar_cost = 15\
	)
	max_integrity = 500

/turf/open/floor/engine/examine(mob/user)
	. = ..()
	. += span_notice("The reinforcement plates are <b>wrenched</b> firmly in place.")

/turf/open/floor/engine/light
	icon_state = "engine_light"

/turf/open/floor/engine/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/engine/airless/light
	icon_state = "engine_light"

/turf/open/floor/engine/break_tile()
	return //unbreakable

/turf/open/floor/engine/burn_tile()
	return //unburnable

/turf/open/floor/engine/make_plating(force = FALSE)
	if(force)
		return ..()
	return //unplateable

/turf/open/floor/engine/try_replace_tile(obj/item/stack/tile/T, mob/user, params)
	return

/turf/open/floor/engine/crowbar_act(mob/living/user, obj/item/I)
	return

/turf/open/floor/engine/wrench_act(mob/living/user, obj/item/I)
	to_chat(user, span_notice("You begin removing plates..."))
	if(I.use_tool(src, user, 30, volume=80))
		if(!istype(src, /turf/open/floor/engine))
			return TRUE
		if(floor_tile)
			new floor_tile(src, 1)
		ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	return TRUE

/turf/open/floor/engine/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		if(floor_tile)
			if(prob(30))
				new floor_tile(src)
				make_plating()
		else if(prob(30))
			ReplaceWithLattice()

/turf/open/floor/engine/attack_paw(mob/user)
	return attack_hand(user)

/turf/open/floor/engine/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	user.Move_Pulled(src)

//air filled floors; used in atmos pressure chambers

/turf/open/floor/engine/n2o
	article = "an"
	name = "\improper N2O floor"
	initial_gas_mix = ATMOS_TANK_N2O

/turf/open/floor/engine/n2o/light
	icon_state = "engine_light"

/turf/open/floor/engine/co2
	name = "\improper CO2 floor"
	initial_gas_mix = ATMOS_TANK_CO2

/turf/open/floor/engine/co2/light
	icon_state = "engine_light"

/turf/open/floor/engine/plasma
	name = "plasma floor"
	initial_gas_mix = ATMOS_TANK_PLASMA

/turf/open/floor/engine/plasma/light
	icon_state = "engine_light"

/turf/open/floor/engine/o2
	name = "\improper O2 floor"
	initial_gas_mix = ATMOS_TANK_O2

/turf/open/floor/engine/o2/light
	icon_state = "engine_light"

/turf/open/floor/engine/n2
	article = "an"
	name = "\improper N2 floor"
	initial_gas_mix = ATMOS_TANK_N2

/turf/open/floor/engine/n2/light
	icon_state = "engine_light"

/turf/open/floor/engine/air
	name = "air floor"
	initial_gas_mix = ATMOS_TANK_AIRMIX

/turf/open/floor/engine/air/light
	icon_state = "engine_light"



/turf/open/floor/engine/cult
	name = "engraved floor"
	desc = "The air smells strangely over this sinister flooring."
	icon_state = "plating"
	floor_tile = null
	var/obj/effect/clockwork/overlay/floor/bloodcult/realappearance
	can_atmos_pass = ATMOS_PASS_NO


/turf/open/floor/engine/cult/Initialize(mapload)
	. = ..()
	if(!mapload)
		new /obj/effect/temp_visual/cult/turf/floor(src)
	realappearance = new /obj/effect/clockwork/overlay/floor/bloodcult(src)
	realappearance.linked = src

/turf/open/floor/engine/cult/Destroy()
	be_removed()
	return ..()

/turf/open/floor/engine/cult/ChangeTurf(path, new_baseturf, flags)
	if(path != type)
		be_removed()
	return ..()

/turf/open/floor/engine/cult/proc/be_removed()
	qdel(realappearance)
	realappearance = null

/turf/open/floor/engine/cult/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/engine/vacuum
	name = "vacuum floor"
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/engine/vacuum/light
	icon_state = "engine_light"
