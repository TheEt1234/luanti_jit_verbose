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
assert(ie, "The jit_verbose mod needs access to insecure environment to import and run jit.v")

local v

do
	local e = ie.getfenv(0)
	setfenv(0, ie)
	v = ie.require("jit.v")
	setfenv(0, e)
end

local started = false

core.register_chatcommand("jv", {
	params = "[filename]",
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
