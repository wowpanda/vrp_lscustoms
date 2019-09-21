--[[
vRP Los Santos Customs V1.2
Credits - MythicalBro and マーモット#2533 for the vRP version and some bug fixes
/////License/////
Do not reupload/re release any part of this script without my permission
]]

local Proxy = module("vrp", "lib/Proxy")
local MySQL = module("vrp_mysql", "MySQL")

local vRP = Proxy.getInterface("vRP")



MySQL.createCommand("vRP/create_modifications_column", "alter table vrp_user_vehicles add if not exists modifications text not null")
MySQL.createCommand("vRP/update_vehicle_modifications", "update vrp_user_vehicles set modifications = @modifications where user_id = @user_id and vehicle = @vehicle")
MySQL.createCommand("vRP/get_vehicle_modifications", "select modifications from vrp_user_vehicles where user_id = @user_id and vehicle = @vehicle")

MySQL.execute("vRP/create_modifications_column")

local tbl = {
[1] = {locked = false, player = nil},
[2] = {locked = false, player = nil},
[3] = {locked = false, player = nil},
[4] = {locked = false, player = nil},
[5] = {locked = false, player = nil},
[6] = {locked = false, player = nil},
}

RegisterServerEvent('lockGarage')
AddEventHandler('lockGarage', function(b,garage)
	tbl[tonumber(garage)].locked = b
	if not b then
		tbl[tonumber(garage)].player = nil
	else
		tbl[tonumber(garage)].player = source
	end
	TriggerClientEvent('lockGarage',-1,tbl)
	print(json.encode(tbl))
end)

RegisterServerEvent('getGarageInfo')
AddEventHandler('getGarageInfo', function()
	TriggerClientEvent('lockGarage',-1,tbl)
	--print(json.encode(tbl))
end)

AddEventHandler('playerDropped', function()
	for i,g in pairs(tbl) do
		if g.player then
			if source == g.player then
				g.locked = false
				g.player = nil
				TriggerClientEvent('lockGarage',-1,tbl)
			end
		end
	end
end)

RegisterServerEvent("LSC:buttonSelected")
AddEventHandler("LSC:buttonSelected", function(name, button)
	local source = source
	local user_id = vRP.getUserId({source})
	if user_id then
		TriggerClientEvent("LSC:buttonSelected", source, name, button, vRP.tryFullPayment({user_id, button.price or 0})) -- money
	end
end)

RegisterServerEvent("LSC:finished")
AddEventHandler("LSC:finished", function(veh)
	local source = source
	local user_id = vRP.getUserId({source})
	if user_id then
		MySQL.execute("vRP/update_vehicle_modifications", {user_id = user_id, vehicle = veh.model, modifications = json.encode({color = veh.color, extraColor = veh.extracolor, neon = veh.neon, neonColor = veh.neoncolor, xenonColor = veh.xenoncolor, smokeColor = veh.smokecolor, wheelType = veh.wheeltype, bulletProofTyres = veh.bulletProofTyres, windowTint = veh.windowtint, plateIndex = veh.plateindex, mods = veh.mods})})
	end
end)

RegisterServerEvent("LSC:applyModifications")
AddEventHandler("LSC:applyModifications", function (model, vehicle)
	local source = source
	local user_id = vRP.getUserId({source})
	if model and vehicle and user_id then
		MySQL.query("vRP/get_vehicle_modifications", {user_id = user_id, vehicle = model}, function (rows, affected)
			if #rows > 0 then
				local modifications = json.decode(rows[1].modifications)
				if modifications then
					TriggerClientEvent("LSC:applyModifications", source, vehicle, modifications)
				end
			end
		end)
	end
end)
