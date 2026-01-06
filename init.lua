--[[
Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
]]

local ie = core.request_insecure_environment()
assert(ie, 'The jit_verbose mod needs access to insecure environment to import and use the "jit.v" module.')

local e = ie.getfenv(0) -- The current environment
local v -- the jit.v module

local load_jit_v = function()
	v = ie.require("jit.v")
end

setfenv(0, ie) -- temporarily exit mod security
local ok, errmsg = pcall(load_jit_v) -- For some reason, if it's without pcall it will not error properly
setfenv(0, e) -- re-instate mod security

if not ok then
	error(
		"\n=== Something went wrong while trying to import jit.v, do you have luaJIT installed on your system? (You need to have it, not just in luanti) ===\n\nThe error:\n"
			.. errmsg
	)
end

local started = false

core.register_chatcommand("jv", {
	params = "[filename]",
	privs = { server = true },
	description = "Starts/stops the verbose mode of luaJIT and flushes all compiled code. If a filename is not provided it will flush to stderr.",
	func = function(name, param)
		started = not started
		if param == "" or param == " " then
			param = nil
		end

		local e = ie.getfenv(0)
		ie.setfenv(0, ie) -- danger
		v.start(param)
		ie.setfenv(0, e) -- no more danger

		if started == true then
			jit.flush() -- first time this function is used in a luanti mod probably
		end
		return true, started and "Started." or "Stopped."
	end,
})
