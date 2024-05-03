return {
	Name = "checkstats",
	Aliases = { "cs", "check", "stats", "data" },
	Description = "Check given player's profile (data). Aliases: cs, data, check, stats",
	Group = "Admin",
	Args = {
		{
			Type = "player # number",
			Name = "player",
			Description = "The player to check stats for",
		},
		{
			Type = "string",
			Name = "table/./..",
			Description = "Optional argument to return the specified table. Type . to view all, .. to include quests.",
		},
	},
}
