function AddTextEntry(key, value)
	Citizen.InvokeNative(GetHashKey("ADD_TEXT_ENTRY"), key, value)
end

Citizen.CreateThread(function()

-- VEHICLES

	AddTextEntry('PATRIOT3A','Patriot M1')

	AddTextEntry('SMOD_SHAL','Shal.Custom')
	AddTextEntry('SMOD_SUB','SUB Magazine')
	AddTextEntry('SMOD_JTR','Jermaine Team Racing')
	AddTextEntry('SMOD_AUTOCOW','Auto Cowboys Garage')
	AddTextEntry('SMOD_DINKA','Dinka')

end)