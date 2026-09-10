function AddTextEntry(key, value)
	Citizen.InvokeNative(GetHashKey("ADD_TEXT_ENTRY"), key, value)
end

Citizen.CreateThread(function()
	AddTextEntry("STRAGE", "Strage")

	-- Modkits --

	-- Bumper F Mods -- 

	AddTextEntry("STRAGE_BUMF1", "Chrome Grill Bumper")
	AddTextEntry("STRAGE_BUMF2", "Black Grill Classic Bumper")
	AddTextEntry("STRAGE_BUMF2A", "Chrome Grill Classic Bumper")

	-- Bumper F Mods -- 

	AddTextEntry("STRAGE_BUMR1", "Classic Bumper")

	-- Bonnet Mods -- 

	AddTextEntry("STRAGE_BNT1", "Double Vent Bonnet")
	AddTextEntry("STRAGE_BNT1a", "Double Vent Carbon Bonnet")
	AddTextEntry("STRAGE_BNT2", "Side Vents Bonnet")
	AddTextEntry("STRAGE_BNT2a", "Side Vents Carbon Bonnet")
	AddTextEntry("STRAGE_BNT3", "Side & Double Vents Bonnet")
	AddTextEntry("STRAGE_BNT3a", "Side & Double Vents Carbon Bonnet")

	-- Bonnet Mods -- 

	AddTextEntry("STRAGE_GRILL1", "Chrome Stock Grill")
	AddTextEntry("STRAGE_GRILL2", "Painted Stock Grill")
	AddTextEntry("STRAGE_GRILL3", "Black Full Face Grill")
	AddTextEntry("STRAGE_GRILL4", "Chrome Full Face Grill")
	AddTextEntry("STRAGE_GRILL5", "Painted Full Face Grill")
	AddTextEntry("STRAGE_GRILL6", "Painted Intake Black")
	AddTextEntry("STRAGE_GRILL7", "Painted Intake Chrome")
	AddTextEntry("STRAGE_GRILL8", "Painted Intake")

	-- Roof Mods --

	AddTextEntry("STRAGE_ROOF1", "Carbon Fibre Roof")

	-- Spoiler Mods -- 

	AddTextEntry("STRAGE_SPOIL1", "Small Painted Spoiler")
	AddTextEntry("STRAGE_SPOIL2", "Small Carbon Fibre Spoiler")
	AddTextEntry("STRAGE_SPOIL3", "Race Spolier")
	AddTextEntry("STRAGE_SPOIL4", "Race Spoiler V2")

	-- Mirror Mods -- 

	AddTextEntry("STRAGE_MIRR1", "Secondary Color Mirror")
	AddTextEntry("STRAGE_MIRR3", "Carbon Fibre Mirrors")

	-- Boot Mods -- 

	AddTextEntry("STRAGE_BOOT1", "Carbon Fibre Boot")

	-- Exhaust Mods -- 

	AddTextEntry("STRAGE_EXH0", "Titanium Stock Exhaust")
	AddTextEntry("STRAGE_EXH0a", "Carbon Fibre Stock Exhaust")
	AddTextEntry("STRAGE_EXH1", "Chrome Slanted Exhaust")
	AddTextEntry("STRAGE_EXH1a", "Titanium Slanted Exhaust")
	AddTextEntry("STRAGE_EXH1b", "Carbon Fibre Slanted Exhaust")

	-- Wing Mods -- 

	AddTextEntry("STRAGE_WING1", "Dual Vent Wings")
	AddTextEntry("STRAGE_WING2", "Single Vent Wings")

	-- Rollcage Mods -- 

	AddTextEntry("STRAGE_INT_ROLL1", "Rollcage")
	AddTextEntry("STRAGE_INT_ROLL2", "Race Rollcage")

    -- Liveries --

	AddTextEntry("STRAGE_LIV1", "Dewbauchee Racing (Black)")
	AddTextEntry("STRAGE_LIV2", "Dewbauchee Racing (White)")
	AddTextEntry("STRAGE_LIV3", "Dewbauchee Stripe (Black)")
	AddTextEntry("STRAGE_LIV4", "Dewbauchee Stripe (White)")
	AddTextEntry("STRAGE_LIV5", "Dewbauchee Stripe (Lime Green)")
	AddTextEntry("STRAGE_LIV6", "Dewbauchee Stripe (Racing Green)")
	AddTextEntry("STRAGE_LIV7", "Dewbauchee Stripe (Blue)")
	AddTextEntry("STRAGE_LIV8", "Dewbauchee Stripe (Pink)")

end)