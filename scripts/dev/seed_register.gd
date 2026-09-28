extends SceneTree
## Writes a demonstration Register: generation 5, a worn world, a few heroes with history.

func _init() -> void:
	var reg := Register.new()
	reg.generation = 5
	reg.world.scores = {"law": 47, "rite": 31, "custom": 26, "tongue": 14, "sea": 52}
	reg.world.institutions["smiths"]["state"] = "Warlords"
	reg.world.institutions["smiths"]["step"] = 1
	reg.world.institutions["smiths"]["moulds"] = 5
	reg.world.institutions["palace"]["state"] = "Standing"
	var a := reg.new_hero("spear", "Arnuwanda", "kessuwat", "greaves", 6)
	a["campaigns"] = 2; a["age_steps"] = 4; a["deeds"] = 7; a["scars"] = ["lamed"]; a["deed_tags"] = ["held:The Kings' Ford", "held:The Kings' Ford", "kill_named:levies"]
	var b := reg.new_hero("sling", "Tudhal", "tarhuna", "bracers", 4)
	b["campaigns"] = 2; b["age_steps"] = 4; b["deeds"] = 5; b["grafts"] = ["bronze_leg"]; b["ink"] = 2
	var c := reg.new_hero("shield", "Muwatti", "kessuwat", "corselet", 3)
	c["campaigns"] = 1; c["age_steps"] = 3; c["deeds"] = 4
	var d := reg.new_hero("spear", "Hattusili", "kessuwat", "greaves", 3)
	d["line"]["parents"] = [a["id"]]; d["memory"] = {"ancestor": "Old Arnu", "ability": "thrust", "charges": 2, "base_charges": 2, "used": 0, "full": true}
	reg.unlocks = {"earned": {"bow_class": 3}, "progress": {"bow_class": 2, "knife_class": 1}}
	reg.chronicle = [{"generation": 4, "state": "won", "day": 19, "text": "The tablets of Kessuwat record a levy raised in the season of the late rains. They held the Salt Crossing on the 11th day."}]
	for h in [a, b, c]:
		h["bonds"] = {}
	reg.save()
	print("seeded ", Register.PATH)
	quit()
