/atom/movable
	var/can_buckle = FALSE
	var/buckle_lying = -1 //bed-like behaviour, forces mob.lying = buckle_lying if != -1
	var/buckle_requires_restraints = 0 //require people to be handcuffed before being able to buckle. eg: pipes
	var/list/buckled_mobs = null //list()
	var/buckle_offset = 0
	var/max_buckled_mobs = 1
	var/buckle_prevents_pull = FALSE

//Interaction
/atom/movable/attack_hand(mob/living/user)
	. = ..()

	if(can_buckle && has_buckled_mobs())
		if(length(buckled_mobs) > 1)
			var/unbuckled = input(user, "Who do you wish to unbuckle?", "Unbuckle Who?") as null|mob in buckled_mobs
			if(isnull(unbuckled))
				return
			if(user_unbuckle_mob(unbuckled,user))
				return TRUE
		else
			if(user_unbuckle_mob(buckled_mobs[1], user))
				return TRUE


/atom/movable/MouseDrop_T(mob/living/M, mob/living/user)
	. = ..()
	if(can_buckle && istype(M) && istype(user))
		if(user_buckle_mob(M, user))
			return TRUE

/atom/movable/proc/has_buckled_mobs()
	return length(buckled_mobs)

/atom/movable/attack_robot(mob/living/user)
	. = ..()
	if(can_buckle && has_buckled_mobs() && Adjacent(user)) // attack_robot is called on all ranges, so the Adjacent check is needed
		if(length(buckled_mobs) > 1)
			var/unbuckled = input(user, "Who do you wish to unbuckle?", "Unbuckle Who?") as null|mob in buckled_mobs
			if(user_unbuckle_mob(unbuckled,user))
				return TRUE
		else
			if(user_unbuckle_mob(buckled_mobs[1], user))
				return TRUE


//procs that handle the actual buckling and unbuckling
/atom/movable/proc/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE)
	if(!buckled_mobs)
		buckled_mobs = list()

	if(!istype(M))
		return FALSE

	if(check_loc && !in_range(M, src))
		return FALSE

	if(M.loc != loc && !M.Move(loc))
		return FALSE

	if((!can_buckle && !force) || M.buckled || (length(buckled_mobs) >= max_buckled_mobs) || (buckle_requires_restraints && !M.restrained()) || M == src)
		return FALSE
	M.buckling = src
	if(!M.can_buckle() && !force)
		if(M == usr)
			to_chat(M, span_warning("You are unable to buckle yourself to [src]!"))
		else
			to_chat(usr, span_warning("You are unable to buckle [M] to [src]!"))
		M.buckling = null
		return FALSE

	if(M.pulledby)
		if(buckle_prevents_pull)
			M.pulledby.stop_pulling()
		else
			M.pulledby.pulling = src
			M.pulledby = null

	for(var/obj/item/grab/G in M.grabbed_by)
		qdel(G)

	M.buckling = null
	M.buckled = src
	M.setDir(dir)
	buckled_mobs |= M
	M.update_canmove()
	M.throw_alert("buckled", /obj/screen/alert/restrained/buckled)
	post_buckle_mob(M)

	SEND_SIGNAL(src, COMSIG_MOVABLE_BUCKLE, M, force)
	return TRUE

/obj/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE)
	. = ..()
	if(.)
		if(resistance_flags & ON_FIRE) //Sets the mob on fire if you buckle them to a burning atom/movableect
			M.adjust_fire_stacks(1)
			M.IgniteMob()

/atom/movable/proc/unbuckle_mob(mob/living/buckled_mob, force = FALSE)
	if(istype(buckled_mob) && buckled_mob.buckled == src && (buckled_mob.can_unbuckle() || force))
		. = buckled_mob
		buckled_mob.buckled = null
		buckled_mob.anchored = initial(buckled_mob.anchored)
		buckled_mob.update_canmove()
		buckled_mob.clear_alert("buckled")
		buckled_mobs -= buckled_mob
		SEND_SIGNAL(src, COMSIG_MOVABLE_UNBUCKLE, buckled_mob, force)

		post_unbuckle_mob(.)

/atom/movable/proc/unbuckle_all_mobs(force = FALSE)
	if(!has_buckled_mobs())
		return
	for(var/m in buckled_mobs)
		unbuckle_mob(m, force)

//Handle any extras after buckling
//Called on buckle_mob()
/atom/movable/proc/post_buckle_mob(mob/living/M)
	return

//same but for unbuckle
/atom/movable/proc/post_unbuckle_mob(mob/living/M)
	return

//Wrapper procs that handle sanity and user feedback
/atom/movable/proc/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if(!in_range(user, src) || !isturf(user.loc) || user.incapacitated() || M.anchored || !in_range(M, src))
		return FALSE

	add_fingerprint(user)

	if(M != user) // Cheks if user interacts with himself
		M.visible_message(span_warning("[user] is trying to buckle [M] to [src]!"),\
					span_warning("[user] is trying to buckle you to [src]!"),\
					span_italics("You hear metal clanking."))
		if(do_mob(user, M, 0.7 SECONDS))
			if(buckle_mob(M, check_loc = check_loc))
				M.visible_message(span_warning("[user] buckles [M] to [src]!"),\
					span_warning("[user] buckles you to [src]!"),\
					span_italics("You hear metal clanking."))
				return TRUE
		else
			to_chat(user, span_warning("You fail to buckle [M]."))
	else
		if(buckle_mob(M, check_loc = check_loc))
			M.visible_message(span_notice("[M] buckles [M.p_them()]self to [src]."),\
				span_notice("You buckle yourself to [src]."),\
				span_italics("You hear metal clanking."))
			return TRUE

/atom/movable/proc/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	var/mob/living/M = unbuckle_mob(buckled_mob)
	if(M)
		if(M != user)
			M.visible_message(span_notice("[user] unbuckles [M] from [src]."),\
				span_notice("[user] unbuckles you from [src]."),\
				span_italics("You hear metal clanking."))
		else
			M.visible_message(span_notice("[M] unbuckles [M.p_them()]self from [src]."),\
				span_notice("You unbuckle yourself from [src]."),\
				span_italics("You hear metal clanking."))
		add_fingerprint(user)
	return M

/mob/living/proc/check_buckled()
	if(buckled && !(buckled in loc))
		buckled.unbuckle_mob(src, force = TRUE)
