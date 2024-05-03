return {
	Name = "unban",
	Aliases = {},
	Description = "Unban the player. This will let the player to join a game again immediately.",
	Group = "Admin",
	Args = {
		{
			Type = "player # string ## number",
			Name = "player",
			Description = "The player to ban. Prefixes (if not in the server): #username, ##id",
		},
		{
			Type = "string",
			Name = "reason",
			Description = "Give the reason. It can be just like 'asked nicely' Set to . for no reason.",
		},
	},
}
