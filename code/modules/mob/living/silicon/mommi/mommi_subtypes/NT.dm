//Nanotrasen MoMMI subtype because we don't give mommis a choice of choosing their module.
/mob/living/silicon/robot/mommi/nt/New()
	pick_module(NANOTRASEN_MOMMI)
	..()
	camera.network = list(CAMERANET_ENGI)
	for (var/obj/machinery/computer/security/engineering/E in tv_monitors)
		E.cyborg_cams += camera
		E.sorted = FALSE