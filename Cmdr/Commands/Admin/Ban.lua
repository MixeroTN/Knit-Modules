return {
	Name = "ban",
	Aliases = {},
	Description = "Ban the player from the game. This will ban the given player even when on another server.",
	Group = "Admin",
	Args = {
		{
			Type = "player # string ## number",
			Name = "player",
			Description = "The player to ban. Prefixes (if not in the server): #username, ##id",
		},
		{
			Type = "string",
			Name = "time of ban",
			Description = "The time player will be banned for. Set to . or 0 for the perm ban. Format example: 1y6mo1d5h4m5s. (years, months, days, hours, minutes, seconds)",
		},
		{
			Type = "string",
			Name = "reason",
			Description = "Give the reason. It can be just like 'exploiting' Set to . for no reason.",
		},
	},
}
