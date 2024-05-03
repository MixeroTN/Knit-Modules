return {
	Name = "teleporttolocation",
	Aliases = { "ttl", "tptl", "teleporttl" },
	Description = "Teleport to a specific NPC or location. Aliases: ttl, tptl, teleportttl",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "player",
			Description = "The player to teleport",
		},
		{
			Type = "string",
			Name = "destination",
			Description = "Name of the location to teleport",
		},
	},
}
