local EntityStatics = {}

-- health 			-> int
-- speed  			-> pixel/second
-- decayInterval	-> second
-- decayAmount 		-> health

EntityStatics.basicDecayMinion = {
	classSource = "hymn.decayingunit",
	health = 10,
	speed = 300,
	decayInterval = 1,
	decayAmount = 1,
}

EntityStatics.spawnPortal = {
	classSource = "hymn.spawnportal",
	health = 25,
	spawnEntityStatics = EntityStatics.basicDecayMinion,
}

return EntityStatics