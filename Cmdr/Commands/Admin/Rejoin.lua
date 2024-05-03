return {
	Name = "rejoin",
	Aliases = { "re", "rj" },
	Description = "Rejoin to the same server. Aliases: re, rj",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "player",
			Description = "Name of the player",
		},
	},
}
