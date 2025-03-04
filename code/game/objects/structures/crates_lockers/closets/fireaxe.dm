//I still dont think this should be a closet but whatever
/obj/structure/closet/fireaxecabinet
	name = "fire axe cabinet"
	desc = "There is small label that reads \"For Emergency use only\" along with details for safe use of the axe. As if."
	icon_state = "fireaxe1000"
	icon_closed = "fireaxe1000"
	icon_opened = "fireaxe1100"
	anchored = TRUE
	density = FALSE
	armor = list("melee" = 50, "bullet" = 20, "laser" = 0, "energy" = 100, "bomb" = 10, "bio" = 100, "rad" = 100, "fire" = 90, "acid" = 50)
	opened = TRUE
	locked = TRUE
	var/obj/item/twohanded/fireaxe/fireaxe
	var/localopened = FALSE //Setting this to keep it from behaviouring like a normal closet and obstructing movement in the map. -Agouri
	var/hitstaken = FALSE
	var/smashed = FALSE


/obj/structure/closet/fireaxecabinet/Initialize(mapload)
	. = ..()
	if(!fireaxe)
		fireaxe = new(src)
		update_icon()


/obj/structure/closet/fireaxecabinet/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Use a multitool to lock/unlock it.</span>"

/obj/structure/closet/fireaxecabinet/attackby(var/obj/item/O as obj, var/mob/living/user as mob)  //Marker -Agouri
	if(isrobot(user) || locked)
		if(istype(O, /obj/item/multitool))
			to_chat(user, "<span class='warning'>Resetting circuitry...</span>")
			playsound(user, 'sound/machines/lockreset.ogg', 50, 1)
			if(do_after(user, 20 * O.toolspeed * gettoolspeedmod(user), target = src))
				add_fingerprint(user)
				locked = FALSE
				to_chat(user, "<span class = 'caution'> You disable the locking modules.</span>")
				update_icon()
			return
		else if(istype(O, /obj/item))
			user.changeNext_move(CLICK_CD_MELEE)
			var/obj/item/W = O
			if(smashed || localopened)
				if(localopened)
					add_fingerprint(user)
					localopened = FALSE
					update_icon_closing()
				return
			else
				user.do_attack_animation(src)
				playsound(user, 'sound/effects/glasshit.ogg', 100, 1) //We don't want this playing every time
			if(W.force < 15)
				to_chat(user, "<span class='notice'>The cabinet's protective glass glances off the hit.</span>")
			else
				hitstaken++
				if(hitstaken == 4)
					playsound(user, 'sound/effects/glassbr3.ogg', 100, 1) //Break cabinet, receive goodies. Cabinet's fucked for life after that.
					smashed = TRUE
					locked = FALSE
					localopened = TRUE
			add_fingerprint(user)
			update_icon()
		return
	if(istype(O, /obj/item/twohanded/fireaxe) && localopened)
		if(!fireaxe)
			var/obj/item/twohanded/fireaxe/F = O
			if(F.wielded)
				to_chat(user, "<span class='warning'>Unwield \the [F] first.</span>")
				return
			if(!user.drop_item_ground(F))
				to_chat(user, "<span class='warning'>\The [F] stays stuck to your hands!</span>")
				return
			add_fingerprint(user)
			fireaxe = F
			contents += F
			to_chat(user, "<span class='notice'>You place \the [F] back in the [name].</span>")
			update_icon()
		else
			if(smashed)
				return
			else
				add_fingerprint(user)
				localopened = !localopened
				if(localopened)
					update_icon_opening()
				else
					update_icon_closing()
	else
		if(smashed)
			return
		if(istype(O, /obj/item/multitool))
			if(localopened)
				add_fingerprint(user)
				localopened = FALSE
				update_icon_closing()
				return
			else
				to_chat(user, "<span class='warning'>Resetting circuitry...</span>")
				playsound(user, 'sound/machines/lockenable.ogg', 50, 1)
				if(do_after(user, 20 * O.toolspeed * gettoolspeedmod(user), target = src))
					add_fingerprint(user)
					locked = TRUE
					to_chat(user, "<span class = 'caution'> You re-enable the locking modules.</span>")
				return
		else
			add_fingerprint(user)
			localopened = !localopened
			if(localopened)
				update_icon_opening()
			else
				update_icon_closing()

/obj/structure/closet/fireaxecabinet/attack_hand(mob/user as mob)
	if(locked)
		to_chat(user, "<span class='warning'>The cabinet won't budge!</span>")
		return
	if(localopened)
		if(fireaxe)
			add_fingerprint(user)
			fireaxe.forceMove_turf()
			user.put_in_hands(fireaxe, ignore_anim = FALSE)
			to_chat(user, "<span class='notice'>You take \the [fireaxe] from the [src].</span>")
			fireaxe = null

			add_fingerprint(user)
			update_icon()
		else
			if(smashed)
				return
			else
				add_fingerprint(user)
				localopened = !localopened
				if(localopened)
					update_icon_opening()
				else
					update_icon_closing()

	else
		add_fingerprint(user)
		localopened = !localopened //I'm pretty sure we don't need an if(smashed) in here. In case I'm wrong and it fucks up teh cabinet, **MARKER**. -Agouri
		if(localopened)
			update_icon_opening()
		else
			update_icon_closing()

/obj/structure/closet/fireaxecabinet/attack_tk(mob/user as mob)
	if(localopened && fireaxe)
		fireaxe.forceMove(loc)
		to_chat(user, "<span class='notice'>You telekinetically remove \the [fireaxe].</span>")
		fireaxe = null
		update_icon()
		return
	attack_hand(user)

/obj/structure/closet/fireaxecabinet/verb/toggle_openness() //nice name, huh? HUH?! -Erro //YEAH -Agouri
	set name = "Open/Close"
	set category = "Object"

	if(isrobot(usr) || locked || smashed)
		if(locked)
			to_chat(usr, "<span class='warning'>The cabinet won't budge!</span>")
		else if(smashed)
			to_chat(usr, "<span class='notice'>The protective glass is broken!</span>")
		return

	localopened = !localopened
	update_icon()

/obj/structure/closet/fireaxecabinet/verb/remove_fire_axe()
	set name = "Remove Fire Axe"
	set category = "Object"

	if(isrobot(usr))
		return

	if(localopened)
		if(fireaxe)
			fireaxe.forceMove_turf()
			usr.put_in_hands(fireaxe, ignore_anim = FALSE)
			to_chat(usr, "<span class='notice'>You take \the [fireaxe] from the [src].</span>")
			fireaxe = null
		else
			to_chat(usr, "<span class='notice'>The [src] is empty.</span>")
	else
		to_chat(usr, "<span class='notice'>The [src] is closed.</span>")
	update_icon()

/obj/structure/closet/fireaxecabinet/attack_ai(mob/user as mob)
	if(smashed)
		to_chat(user, "<span class='warning'>The security of the cabinet is compromised.</span>")
		return
	else
		locked = !locked
		if(locked)
			to_chat(user, "<span class='warning'>Cabinet locked.</span>")
		else
			to_chat(user, "<span class='notice'>Cabinet unlocked.</span>")

/obj/structure/closet/fireaxecabinet/proc/update_icon_opening()
	var/hasaxe = fireaxe != null
	icon_state = "fireaxe[hasaxe][localopened][hitstaken][smashed]opening"
	spawn(10)
		update_icon()

/obj/structure/closet/fireaxecabinet/proc/update_icon_closing()
	var/hasaxe = fireaxe != null
	icon_state = "fireaxe[hasaxe][localopened][hitstaken][smashed]closing"
	spawn(10)
		update_icon()

/obj/structure/closet/fireaxecabinet/update_icon() //Template: fireaxe[has fireaxe][is opened][hits taken][is smashed]. If you want the opening or closing animations, add "opening" or "closing" right after the numbers
	var/hasaxe = fireaxe != null
	icon_state = "fireaxe[hasaxe][localopened][hitstaken][smashed]"

/obj/structure/closet/fireaxecabinet/open()
	return

/obj/structure/closet/fireaxecabinet/close()
	return

/obj/structure/closet/fireaxecabinet/welder_act(mob/user, obj/item/I) //A bastion of sanity in a sea of madness
	return

/obj/structure/closet/fireaxecabinet/Destroy()
	if(!obj_integrity)
		if(fireaxe)
			fireaxe.forceMove(loc)
			fireaxe = null
		else
			QDEL_NULL(fireaxe)
	return ..()

//mining "fireaxe"
/obj/structure/fishingrodcabinet
	name = "fishing cabinet"
	desc = "There is a small label that reads \"Fo* Em**gen*y u*e *nly\". All the other text is scratched out and replaced with various fish weights."
	icon = 'icons/obj/closet.dmi'
	icon_state = "fishingrod"
	anchored = TRUE
	var/obj/item/twohanded/fishingrod/olreliable //what the fuck?

/obj/structure/fishingrodcabinet/Initialize()
	. = ..()
	if(!olreliable)
		olreliable = new(src)
		update_icon()

/obj/structure/fishingrodcabinet/update_icon()
	. = ..()
	cut_overlays()
	if(olreliable)
		add_overlay("rod")

/obj/structure/fishingrodcabinet/attackby(var/obj/item/O as obj, var/mob/living/user as mob)
	if(istype(O, /obj/item/twohanded/fishingrod))
		var/obj/item/twohanded/fishingrod/R = O
		if(R.wielded)
			to_chat(user, "<span class='warning'>Unwield \the [R] first.</span>")
			return
		if(!user.drop_item_ground(R))
			to_chat(user, "<span class='warning'>\The [R] stays stuck to your hands!</span>")
			return
		add_fingerprint(user)
		olreliable = R
		contents += R
		to_chat(user, "<span class='notice'>You place \the [R] back in the [name].</span>")
		update_icon()



/obj/structure/fishingrodcabinet/attack_hand(mob/user as mob)
	if(olreliable)
		add_fingerprint(user)
		olreliable.forceMove_turf()
		user.put_in_hands(olreliable, ignore_anim = FALSE)
		to_chat(user, "<span class='notice'>You take \the [olreliable] from the [src].</span>")
		olreliable = null

		add_fingerprint(user)
		update_icon()
