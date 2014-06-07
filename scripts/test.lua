--[=[--

	TG BOT

	Copyright (c) 2014 Patrick Louis, patrick at iotek dot org.

	Permission to use, copy, modify, and distribute this software for any
	purpose with or without fee is hereby granted, provided that the above
	copyright notice and this permission notice appear in all copies.

	THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
	WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
	ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
	WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
	ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
	OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. */

--]=]--

--[[CONFIG LOCATIONS AND GLOBAL VARS]]--

our_id          = "your_id_here" --replace this with your own id
now             = os.time()
config_location = os.getenv("HOME").."/.telegram/scripts/config"
clever_location = os.getenv("HOME").."/.telegram/scripts/node/scripts/clever.js"
dictio_location = os.getenv("HOME").."/.telegram/scripts/node/scripts/dictio.js"
knows_i_m_away  = {}
away_msg        = ""

help = function()
	return [=[

	help()            : Display this usage information
	dice()            : Returns a random number 1-6
	quote()           : Returns a random fortune cookie quote
	ping()            : Pong back
	weather()         : Returns the weather status
	md5(string)       : Returns the md5 hash of the string
	sha256(string)    : Returns the sha256 of the string
	define(word)      : Returns the definition of a word
	cleverbot(string) : Ask the cleverbot something
	note(something)   : If away, it will save a note for me
	]=]
end

function check_configs()
	local config              = io.open(config_location,'r')
	local bot_on              = config:read("*l")
	local cleverbot_always_on = config:read("*l")
	local away_on             = config:read("*l")
	away_msg                  = config:read("*l")
	--remove comments
	bot_on                    = string.gsub(bot_on, "(#.*)", "") 
	cleverbot_always_on       = string.gsub(cleverbot_always_on, "(#.*)", "")
	away_on                   = string.gsub(away_on, "(#.*)", "") 
	config:close()
	config                    = nil
	bot_on                    = tonumber(bot_on) ==1
	cleverbot_always_on       = tonumber(cleverbot_always_on) ==1
	away_on                   = tonumber(away_on) ==1
	return bot_on, cleverbot_always_on,away_on
end

function user_knows_i_m_away(user)
	for k,v in pairs(knows_i_m_away) do
		if v ==user then
			return true
		end
	end
	table.insert(knows_i_m_away, user)
	return false
end

function write_email(user, date, content)
	name = os.tmpname()
	f = io.open(name, 'w')
	f:write("NOTE\n")
	f:write("\n")
	f:write(
			"-START-\n\n"..
			"USER: "..user..
			"\nDATE: "..date..
			"\nCONTENT:"..content..
			"\n\n-END-\n\n")
	f:flush()
	os.execute("/usr/lib/nmh/rcvstore < "..name)
	os.remove(name)
end

function return_command_output(command)
	local execute  = io.popen(command)
	local result = execute:read("*a")
	execute:close()
	return result
end

function send_msg_wrapper(msg, text)
	if msg.to.print_name ~= our_id then
		send_msg( msg.to.print_name, text)
	else 
		send_msg(msg.from.print_name, text)
	end
end

function simple_command(msg)
	command = string.lower(msg.text)
	if command == 'ping()' then
		send_msg (msg.from.print_name, 'pong')
	elseif command == 'dice()' then
		send_msg_wrapper(
			msg, 
			return_command_output(
				[[ echo $((0x$(head -c5 /dev/random|xxd -ps)%6+1))]]
			)
		)
	elseif command == 'quote()' then
		send_msg_wrapper(
			msg, 
			return_command_output(
				[[ fortune ]]
			)
		)
	elseif command =='weather()' then
		send_msg_wrapper(
			msg,
			return_command_output(
				[[cat -s .my_updater/data | grep -E "WEATHER"]]
			).. [[

			]] ..
			return_command_output(
				[[cat -s .my_updater/data | grep -E "TOMORROW"]]
			).. [[

			]] ..
			return_command_output(
				[[cat -s .my_updater/data | grep -E "TEMP:"]]
			)..[[

			]]
		)
	elseif command == "help()" then
		send_msg_wrapper(
			msg,
			help()
		)
	end
end

function complex_command(msg, command,param, away)
	command = string.lower(command)
	param   = string.gsub(param, "'", "") --preventing code injection
	if command == "md5" then
		send_msg_wrapper( 
			msg,
			return_command_output(
				"echo '"..param.."'".." | md5sum"
			)
		)
	elseif command == "sha256" then
		send_msg_wrapper( 
			msg,
				return_command_output(
				"echo '"..param.."'".." | sha256sum"
			)
		)
	elseif command == "define" then
		send_msg_wrapper(
			msg,
			return_command_output(
				"node "..dictio_location.." '"..param.."'"
			)
		)
	elseif command == "cleverbot" then
		send_msg_wrapper(
			msg,
			return_command_output(
				"node "..clever_location.." '".. param.."'"
			)
		)
	elseif command == "note" and away then
		write_email(msg.from.print_name, msg.date, param)
		send_msg_wrapper( 
			msg,
			"Message '"..param.."' from "..msg.from.phone.." was noted"
		)
	end
end

function handle_messages(msg,away)
	if string.match(msg.text, "%(%)") then
		simple_command(msg)
	elseif (string.match(msg.text, "%(")) then
		command = string.match(msg.text, [[%w*]])
		param   = string.gsub(msg.text, command.."[%s]*", "")
		param   = string.gsub(param, "%(", "")
		param   = string.gsub(param, "%)", "")
		complex_command(msg, command, param, away)
	end
end

function cleverbot_handle_messages(msg)
	param = string.gsub(msg.text, "'", "")
	send_msg_wrapper(
		msg,
		return_command_output(
			"node "..clever_location.." '".. param.."'"
		)
	)
end

function vardump(value, depth, key)
	local line_prefix = ""
	local spaces = ""
	
	if key ~= nil then
		line_prefix = "["..key.."] = "
	end
	
	if depth == nil then
		depth = 0
	else
		depth = depth + 1
		for i=1, depth do spaces = spaces .. "  " end
	end
	
	if type(value) == 'table' then
		mTable = getmetatable(value)
		if mTable == nil then
			print(spaces ..line_prefix.."(table) ")
		else
		print(spaces .."(metatable) ")
			value = mTable
		end		
		for table_key, table_value in pairs(value) do
			vardump(table_value, depth, table_key)
		end
	elseif type(value)	== 'function' or 
		type(value)	== 'thread' or 
		type(value)	== 'userdata' or
		value		== nil
	then
		print(spaces..tostring(value))
	else
		print(spaces..line_prefix.."("..type(value)..") "..tostring(value))
	end
end

print ("HI, this is a motherfuckin lua script")

function on_msg_receive (msg)
	if msg.date < now then
		return
	end
	if msg.out then
		return
	end
	if msg.text == nil then
		return
	end
	if msg.unread == 0 then
		return
	end
	bot, clever, away = check_configs()

	if (away)  then
		sender = ""
		if msg.to.print_name ~= our_id then
			sender = msg.to.print_name
		else
			sender = msg.from.print_name
		end
		if (not user_knows_i_m_away(sender)) then
			send_msg_wrapper(msg, away_msg)
		end
	else
		knows_i_m_away = {} --reinitialize the list
	end

	if (clever) then
		cleverbot_handle_messages(msg)
	elseif (bot) then
		os.execute("notif '"..msg.from.print_name.." ====> ".. string.gsub(msg.text, "'", "").."'&")
		handle_messages(msg,away)
	else 
		os.execute("notif '"..msg.from.print_name.." ====> ".. string.gsub(param, "'", "").."'&")
	end

--	vardump (msg)
end

function on_our_id (id)
	print("MY ID IS"..id)
	our_id = id
end

function on_secret_chat_created (peer)
	--vardump (peer)
end

function on_user_update (user)
	--vardump (user)
end

function on_chat_update (user)
	--vardump (user)
end

function on_get_difference_end ()
end

function on_binlog_replay_end ()
end
