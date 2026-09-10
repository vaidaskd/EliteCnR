function i(key, value)
    Citizen.InvokeNative(GetHashKey("ADD_TEXT_ENTRY"), key, value)
end

Citizen.CreateThread(function()
    i("PGRANGER2", "Police Granger 3600XL")
end)
