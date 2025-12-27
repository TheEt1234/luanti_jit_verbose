Imports the verbose mode of the LuaJIT compiler. (Does the same thing as `luajit -jv <filename>`)

This is the tool you can use when you don't know what to do even with the luaJIT profiler.

After you don't know what to do after using this tool, you should consider creating a mod that does the same thing as the `-jdump` option, or just try asking in the luanti discord server for improvements.

## Usage

This mod registers a `/jv` command. Simply run it (`/jv` with no arguments) and you will have the verbose output in the terminal you launched luanti from.

That gets noisy really fast, so you should instead specify a file with `/jv <filename>`, for example i like to do: `/jv /tmp/verbose_jit.txt`

It's a lot easier to browse it as a file and see what you want.

### Okay but how do i read that? What should i be concerned about?

If there are certain lines of code you want to be optimising, then search for them in the file you put to `/jv`.  
Example: if you want to optimize `my_mod_something.lua`, from line 100 to 200, then you could search for `my_mod_something.lua:1` and `my_mod_something.lua:2` in your editor.

You should be concerned about "NYI" (stands for Not Yet Implemented) mainly, and try avoiding functions that are stiches. 

Here is a possibly outdated and unofficial list of all things NYI: https://github.com/tarantool/tarantool/wiki/LuaJIT-Not-Yet-Implemented (i don't know why luaJIT wiki stopped being a thing)

For a better answer, see the comments in `/usr/share/luajit-2.1/jit/v.lua`:
```
The copyright notice for this:

LuaJIT -- a Just-In-Time Compiler for Lua. https://luajit.org/

Copyright (C) 2005-2025 Mike Pall. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

--------------------------------------------------------------------------
Verbose mode of the LuaJIT compiler.

Copyright (C) 2005-2025 Mike Pall. All rights reserved.
Released under the MIT license. See Copyright Notice in luajit.h
--------------------------------------------------------------------------

This module shows verbose information about the progress of the
JIT compiler. It prints one line for each generated trace. This module
is useful to see which code has been compiled or where the compiler
punts and falls back to the interpreter.

Example usage:

  luajit -jv -e "for i=1,1000 do for j=1,1000 do end end"
  luajit -jv=myapp.out myapp.lua

Default output is to stderr. To redirect the output to a file, pass a
filename as an argument (use '-' for stdout) or set the environment
variable LUAJIT_VERBOSEFILE. The file is overwritten every time the
module is started.

The output from the first example should look like this:

[TRACE   1 (command line):1 loop]
[TRACE   2 (1/3) (command line):1 -> 1]

The first number in each line is the internal trace number. Next are
the file name ('(command line)') and the line number (':1') where the
trace has started. Side traces also show the parent trace number and
the exit number where they are attached to in parentheses ('(1/3)').
An arrow at the end shows where the trace links to ('-> 1'), unless
it loops to itself.

In this case the inner loop gets hot and is traced first, generating
a root trace. Then the last exit from the 1st trace gets hot, too,
and triggers generation of the 2nd trace. The side trace follows the
path along the outer loop and *around* the inner loop, back to its
start, and then links to the 1st trace. Yes, this may seem unusual,
if you know how traditional compilers work. Trace compilers are full
of surprises like this -- have fun! :-)

Aborted traces are shown like this:

[TRACE --- foo.lua:44 -- leaving loop in root trace at foo:lua:50]

Don't worry -- trace aborts are quite common, even in programs which
can be fully compiled. The compiler may retry several times until it
finds a suitable trace.

Of course this doesn't work with features that are not-yet-implemented
(NYI error messages). The VM simply falls back to the interpreter. This
may not matter at all if the particular trace is not very high up in
the CPU usage profile. Oh, and the interpreter is quite fast, too.

Also check out the -jdump module, which prints all the gory details.
```


### A little "story" (please don't skip)

We all love luaJIT right? It makes our code faster for free.  
But often, it could make our code even faster if we just change some small details, or run a lot slower than it should if we do something wrong.

Consider the code:
```lua
local t = { 1, 1, 1 }
for i = 1, 10000000 do
	t[#t + 1] = t[#t - 1] + t[#t - 2]
end

print("Done")
```

Let's benchmark it on luaJIT and on lua5.4

```
❯ : hyperfine -i "luajit bad.lua" "lua bad.lua"
Benchmark 1: luajit bad.lua
  Time (mean ± σ):      90.5 ms ±   5.8 ms    [User: 65.3 ms, System: 24.7 ms]
  Range (min … max):    81.3 ms … 104.6 ms    30 runs

Benchmark 2: lua bad.lua
  Time (mean ± σ):     706.2 ms ±  26.4 ms    [User: 616.4 ms, System: 87.6 ms]
  Range (min … max):   679.7 ms … 760.1 ms    10 runs

Summary
  luajit bad.lua ran
    7.80 ± 0.58 times faster than lua bad.lua
```

WOW! LuaJIT ran 8 times faster, that is amazing!


I wonder what will happen if we change this code a little bit...

```lua
local t = { 1, 1, 1 }
for i = 1, 10000000 do
    t[-i] = t[i] -- Added! Surely nothing bad will happen
	t[#t + 1] = t[#t - 1] + t[#t - 2]
end

print("Done")
```

Hmm... luaJIT seems awfully slow today, must be the weather, WAIT why does it say that the current estimate is 9 seconds!?

> [!NOTE]
> Benchmark times also include the startup time, which i assume for luaJIT is higher
```
Benchmark 1: luajit bad.lua
  Time (mean ± σ):      9.180 s ±  0.759 s    [User: 8.587 s, System: 0.496 s]
  Range (min … max):    8.160 s … 10.935 s    10 runs

Benchmark 2: lua bad.lua
  Time (mean ± σ):      2.372 s ±  0.453 s    [User: 1.833 s, System: 0.523 s]
  Range (min … max):    2.106 s …  3.373 s    10 runs

  Warning: Statistical outliers were detected. Consider re-running this benchmark on a quiet system without any interferences from other programs. It might help to use the '--warmup' or '--prepare' options.

Summary
  lua bad.lua ran
    3.87 ± 0.81 times faster than luajit bad.lua
```

What???? HOW????

Okay, what went wrong here, what, how did it go from 7x faster to 3x slower with such a trivial change??

Let's see, is there any way to get information from the JIT compiler?  
From the [luajit.org](https://luajit.org/running.html) website: Yes! 

```
-j cmd[=arg[,arg...]]

This option performs a LuaJIT control command or activates one of the loadable extension modules. The command is first looked up in the jit.* library. If no matching function is found, a module named jit.<cmd> is loaded and the start() function of the module is called with the specified arguments (if any). The space between -j and cmd is optional.

Here are the available LuaJIT control commands:

    -jon — Turns the JIT compiler on (default).
    -joff — Turns the JIT compiler off (only use the interpreter).
    -jflush — Flushes the whole cache of compiled code.
    -jv — Shows verbose information about the progress of the JIT compiler.
    -jdump — Dumps the code and structures used in various compiler stages.
    -jp — Start the integrated profiler.

```

The `-jv` option sounds interesting, let's see what happened...

```
❯ : luajit -jv bad.lua
[TRACE --- bad.lua:2 -- NYI: mixed sparse/dense table at bad.lua:3]
[TRACE --- bad.lua:2 -- NYI: mixed sparse/dense table at bad.lua:3]
[TRACE --- bad.lua:2 -- NYI: mixed sparse/dense table at bad.lua:3]
[TRACE --- bad.lua:2 -- NYI: mixed sparse/dense table at bad.lua:3]
[TRACE --- bad.lua:2 -- NYI: mixed sparse/dense table at bad.lua:3]
[TRACE --- bad.lua:2 -- NYI: mixed sparse/dense table at bad.lua:3]
[TRACE --- bad.lua:2 -- NYI: mixed sparse/dense table at bad.lua:3]
[TRACE --- bad.lua:2 -- NYI: mixed sparse/dense table at bad.lua:3]
[TRACE --- bad.lua:2 -- NYI: mixed sparse/dense table at bad.lua:3]
[TRACE --- bad.lua:2 -- NYI: mixed sparse/dense table at bad.lua:3]
[TRACE --- bad.lua:2 -- NYI: mixed sparse/dense table at bad.lua:3]
Done
```

Oh? interesting...

The line 3 of `bad.lua` is

```
    t[-i] = t[i]
```

I think luaJIT couldn't compile that, so the function was slower. Thanks `/usr/share/luajit-2.1/jit/v.lua` I appreciate it.

<br>
<br>

I can hear you asking about lua5.1 with that code. Sure, i will benchmark it.


```lua
local t = { 1, 1, 1 }
for i = 1, 10000000 do
	t[-i] = t[i]
	t[#t + 1] = t[#t - 1] + t[#t - 2]
end

print("Done")
```

> [!NOTE]
> Benchmark times also include the startup time, which i assume for luaJIT is higher
```
❯ : hyperfine -i "luajit bad.lua" "lua5.1 bad.lua"
Benchmark 1: luajit bad.lua
  Time (mean ± σ):     10.446 s ±  1.416 s    [User: 9.596 s, System: 0.710 s]
  Range (min … max):    8.656 s … 12.702 s    10 runs

Benchmark 2: lua5.1 bad.lua
  Time (mean ± σ):      7.007 s ±  0.623 s    [User: 5.829 s, System: 1.129 s]
  Range (min … max):    6.227 s …  8.062 s    10 runs

Summary
  lua5.1 bad.lua ran
    1.49 ± 0.24 times faster than luajit bad.lua
```

LuaJIT will still generally be faster than Lua5.1 or Lua5.4 if you don't do anything bizzare, and a lot faster if you optimize that code for luaJIT.
