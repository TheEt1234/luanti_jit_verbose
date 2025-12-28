Imports the verbose mode of the LuaJIT compiler. (Does the same thing as `luajit -jv <filename>`)

This is the tool you can use when you don't know what to do even after using luajit's profiler (but have specific functions in mind that you hope to optimize).

After you don't know what to do after using this tool, you should consider creating a mod that does the same thing as the `-jdump` option in luajit, or just try asking in the luanti discord server for ideas on improvements.

## Requirements

You must have luajit installed on your system, or have some way for `require` to detect the `jit.v` module.

## Usage

This mod registers a `/jv` command. Simply run it (`/jv` with no arguments) and you will have the verbose output in the terminal you launched luanti from.

That gets noisy, so you should instead specify a file with `/jv <filename>`, for example i like to do: `/jv /tmp/verbose_jit.txt`

It's a lot easier to browse it as a file and see what you want.

### Okay but how do i read that? What should i be concerned about?

If there are certain lines of code you want to be optimising, then search for them in the file you put to `/jv`.  
Example: if you want to optimize `my_mod_something.lua`, from line 100 to 200, then you could search for `my_mod_something.lua:1` and `my_mod_something.lua:2` in your editor.

You should be concerned about "NYI" (Not Yet Implemented, this means luaJIT can't compile your code), and you should try avoiding calling functions that are stiches.

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
