return {
	Name = "banhistory",
	Aliases = { "bh", "banh", "bhist", "banhist" },
	Description = "[THIS ACTION WILL KICK THE PLAYER WHEN USING A PREFIX] Browse the ban and unban history of the player. Aliases: bh, banh, bhist, banhist",
	Group = "Admin",
	Args = {
		{
			Type = "player # string ## number",
			Name = "player",
			Description = "The player to view the history of. Prefixes (if not in the server): #username, ##id",
		},
	},
}
