
DISCLAIMER - ABANDONED/UNMAINTAINED CODE / DO NOT USE
=======================================================
While this repository has been inactive for some time, this formal notice, issued on **December 10, 2024**, serves as the official declaration to clarify the situation. Consequently, this repository and all associated resources (including related projects, code, documentation, and distributed packages such as Docker images, PyPI packages, etc.) are now explicitly declared **unmaintained** and **abandoned**.

I would like to remind everyone that this project’s free license has always been based on the principle that the software is provided "AS-IS", without any warranty or expectation of liability or maintenance from the maintainer.
As such, it is used solely at the user's own risk, with no warranty or liability from the maintainer, including but not limited to any damages arising from its use.

Due to the enactment of the Cyber Resilience Act (EU Regulation 2024/2847), which significantly alters the regulatory framework, including penalties of up to €15M, combined with its demands for **unpaid** and **indefinite** liability, it has become untenable for me to continue maintaining all my Open Source Projects as a natural person.
The new regulations impose personal liability risks and create an unacceptable burden, regardless of my personal situation now or in the future, particularly when the work is done voluntarily and without compensation.

**No further technical support, updates (including security patches), or maintenance, of any kind, will be provided.**

These resources may remain online, but solely for public archiving, documentation, and educational purposes.

Users are strongly advised not to use these resources in any active or production-related projects, and to seek alternative solutions that comply with the new legal requirements (EU CRA).

**Using these resources outside of these contexts is strictly prohibited and is done at your own risk.**

This project has been transfered to Makina Corpus <freesoftware@makina-corpus.com> ( https://makina-corpus.com ). This project and its associated resources, including published resources related to this project (e.g., from PyPI, Docker Hub, GitHub, etc.), may be removed starting **March 15, 2025**, especially if the CRA’s risks remain disproportionate.

# Name

openresty/luajit2 - OpenResty's maintained branch of LuaJIT.

Table of Contents
=================

* [Name](#name)
* [Description](#description)
* [OpenResty extensions](#openresty-extensions)
    * [New Lua APIs](#new-lua-apis)
        * [table.isempty](#tableisempty)
        * [table.isarray](#tableisarray)
        * [table.nkeys](#tablenkeys)
        * [table.clone](#tableclone)
        * [jit.prngstate](#jitprngstate)
        * [thread.exdata](#threadexdata)
        * [thread.exdata2](#threadexdata2)
    * [New C API](#new-c-api)
        * [lua_setexdata](#lua_setexdata)
        * [lua_getexdata](#lua_getexdata)
        * [lua_setexdata2](#lua_setexdata2)
        * [lua_getexdata2](#lua_getexdata2)
        * [lua_resetthread](#lua_resetthread)
    * [New macros](#new-macros)
        * [`OPENRESTY_LUAJIT`](#openresty_luajit)
        * [`HAVE_LUA_RESETTHREAD`](#have_lua_resetthread)
    * [Optimizations](#optimizations)
        * [Updated JIT default parameters](#updated-jit-default-parameters)
        * [String hashing](#string-hashing)
    * [Updated bytecode options](#updated-bytecode-options)
        * [New `-bL` option](#new--bl-option)
        * [Updated `-bl` option](#updated--bl-option)
    * [Miscellaneous](#miscellaneous)
* [Copyright & License](#copyright--license)

# Description

This is the official OpenResty branch of LuaJIT. It is not to be considered a
fork, since we still regularly synchronize changes from the upstream LuaJIT
project (https://github.com/LuaJIT/LuaJIT).

# OpenResty extensions

Additionally to synchronizing upstream changes, we introduce our own changes
which haven't been merged yet (or never will be). This document describes those
changes that are specific to this branch.

## New Lua APIs

### table.isempty

**syntax:** *res = isempty(tab)*

Returns `true` when the given Lua table contains neither non-nil array elements
nor non-nil key-value pairs, or `false` otherwise.

This API can be JIT compiled.

Usage:

```lua
local isempty = require "table.isempty"

print(isempty({}))  -- true
print(isempty({nil, dog = nil}))  -- true
print(isempty({"a", "b"}))  -- false
print(isempty({nil, 3}))  -- false
print(isempty({cat = 3}))  -- false
```

[Back to TOC](#table-of-contents)

### table.isarray

**syntax:** *res = isarray(tab)*

Returns `true` when the given Lua table is a pure array-like Lua table, or
`false` otherwise.

Empty Lua tables are treated as arrays.

This API can be JIT compiled.

Usage:

```lua
local isarray = require "table.isarray"

print(isarray{"a", true, 3.14})  -- true
print(isarray{dog = 3})  -- false
print(isarray{})  -- true
```

[Back to TOC](#table-of-contents)

### table.nkeys

**syntax:** *n = nkeys(tab)*

Returns the total number of elements in a given Lua table (i.e. from both the
array and hash parts combined).

This API can be JIT compiled.

Usage:

```lua
local nkeys = require "table.nkeys"

print(nkeys({}))  -- 0
print(nkeys({ "a", nil, "b" }))  -- 2
print(nkeys({ dog = 3, cat = 4, bird = nil }))  -- 2
print(nkeys({ "a", dog = 3, cat = 4 }))  -- 3
```

[Back to TOC](#table-of-contents)

### table.clone

**syntax:** *t = clone(tab)*

Returns a shallow copy of the given Lua table.

This API can be JIT compiled.

Usage:

```lua
local clone = require "table.clone"

local x = {x=12, y={5, 6, 7}}
local y = clone(x)
... use y ...
```

**Note:** We observe 7% over-all speedup in the edgelang-fan compiler's
compiling speed whose Lua is generated by the fanlang compiler.

**Note bis:** Deep cloning is planned to be supported by adding `true` as a
second argument.

[Back to TOC](#table-of-contents)

### jit.prngstate

**syntax:** *state = jit.prngstate(state?)*

Returns (and optionally sets) the current PRNG state (an array of 8 Lua
numbers with 32-bit integer values) currently used by the JIT compiler.

When the `state` argument is non-nil, it is expected to be an array of up to 8
unsigned Lua numbers, each with value less than 2\*\*32-1. This will set the
current PRNG state and return the state that was overridden.

**Note:** For backward compatibility, `state` argument can also be an unsigned
Lua number less than 2\*\*32-1.

**Note:** When the `state` argument is an array and less than 8 numbers, or the
`state` is a number, the remaining positions are filled with zeros.

Usage:

```lua
local state = jit.prngstate()
local oldstate = jit.prngstate{ a, b, c, ... }

jit.prngstate(32) -- {32, 0, 0, 0, 0, 0, 0, 0}
jit.prngstate{432, 23, 50} -- {432, 23, 50, 0, 0, 0, 0, 0}
```

**Note:** This API has no effect if LuaJIT is compiled with
`-DLUAJIT_DISABLE_JIT`, and will return a table with all `0`.

[Back to TOC](#table-of-contents)

### thread.exdata

**syntax:** *exdata = th_exdata(data?)*

This API allows for embedding user data into a thread (`lua_State`).

The retrieved `exdata` value on the Lua land is represented as a cdata object
of the ctype `void*`.

As of this version, retrieving the `exdata` (i.e. `th_exdata()` without any
argument) can be JIT compiled.

Usage:

```lua
local th_exdata = require "thread.exdata"

th_exdata(0xdeadbeefLL)  -- set the exdata of the current Lua thread
local exdata = th_exdata()  -- fetch the exdata of the current Lua thread
```

Also available are the following public C API functions for manipulating
`exdata` on the C land:

```C
void lua_setexdata(lua_State *L, void *exdata);
void *lua_getexdata(lua_State *L);
```

The `exdata` pointer is initialized to `NULL` when the main thread is created.
Any child Lua thread will inherit its parent's `exdata`, but still can override
it.

**Note:** This API will not be available if LuaJIT is compiled with
`-DLUAJIT_DISABLE_FFI`.

**Note bis:** This API is used internally by the OpenResty core, and it is
strongly discouraged to use it yourself in the context of OpenResty.

[Back to TOC](#table-of-contents)

### thread.exdata2

**syntax:** *exdata = th_exdata2(data?)*

Similar to `thread.exdata` but for a 2nd separate user data as a pointer value.

[Back to TOC](#table-of-contents)

## New C API

### lua_setexdata

```C
void lua_setexdata(lua_State *L, void *exdata);
```

Sets extra user data as a pointer value to the current Lua state or thread.

[Back to TOC](#table-of-contents)

### lua_getexdata

```C
void *lua_getexdata(lua_State *L);
```

Gets extra user data as a pointer value to the current Lua state or thread.

[Back to TOC](#table-of-contents)

### lua_setexdata2

```C
void lua_setexdata2(lua_State *L, void *exdata2);
```

Similar to `lua_setexdata` but for a 2nd user data (pointer) value.

[Back to TOC](#table-of-contents)

### lua_getexdata2

```C
void *lua_getexdata2(lua_State *L);
```

Similar to `lua_getexdata` but for a 2nd user data (pointer) value.

[Back to TOC](#table-of-contents)

### lua_resetthread

```C
void lua_resetthread(lua_State *L, lua_State *th);
```

Resets the state of `th` to the initial state of a newly created Lua thread
object as returned by `lua_newthread()`. This is mainly for Lua thread
recycling. Lua threads in arbitrary states (like yielded or errored) can be
reset properly.

The current implementation does not shrink the already allocated Lua stack
though. It only clears it.

[Back to TOC](#table-of-contents)

## New macros

The macros described in this section have been added to this branch.

[Back to TOC](#table-of-contents)

### `OPENRESTY_LUAJIT`

In the `luajit.h` header file, a new macro `OPENRESTY_LUAJIT` was defined to
help distinguishing this OpenResty-specific branch of LuaJIT.

### `HAVE_LUA_RESETTHREAD`

This macro is set when the `lua_resetthread` C API is present.

[Back to TOC](#table-of-contents)

## Optimizations

### Updated JIT default parameters

We use more appressive default JIT compiler options to help large OpenResty
Lua applications.

The following `jit.opt` options are used by default:

```lua
maxtrace=8000
maxrecord=16000
minstitch=3
maxmcode=40960  -- in KB
```

[Back to TOC](#table-of-contents)

### String hashing

This optimization only applies to Intel CPUs supporting the SSE 4.2 instruction
sets. For such CPUs, and when this branch is compiled with `-msse4.2`, the
string hashing function used for strings interning will be based on an
optimized crc32 implementation (see `lj_str_new()`).

This optimization still provides constant-time hashing complexity (`O(n)`), but
makes hash collision attacks harder for strings up to 127 bytes of size.

[Back to TOC](#table-of-contents)

## Updated bytecode options

### New `-bL` option

The bytecode option `L` was added to display Lua sources line numbers.

For example, `luajit -bL -e 'print(1)'` now produces bytecode dumps like below:

```
-- BYTECODE -- "print(1)":0-1
0001     [1]    GGET     0   0      ; "print"
0002     [1]    KSHORT   1   1
0003     [1]    CALL     0   1   2
0004     [1]    RET0     0   1
```

The `[N]` column corresponds to the Lua source line number. For example, `[1]`
means "the first source line".

[Back to TOC](#table-of-contents)

### Updated `-bl` option

The bytecode option `l` was updated to display the constant tables of each Lua
prototype.

For example, `luajit -bl a.lua'` now produces bytecode dumps like below:

```
-- BYTECODE -- a.lua:0-48
KGC    0    "print"
KGC    1    "hi"
KGC    2    table
KGC    3    a.lua:17
KN    1    1000000
KN    2    1.390671161567e-309
...
```

[Back to TOC](#table-of-contents)

## Miscellaneous

* Increased the maximum number of allowed upvalues from 60 to 120.
* Various important bugfixes in the JIT compiler and Lua VM which have
  not been merged in upstream LuaJIT.
* Removed the GCC 4 requirement for x86 on older systems such as Solaris i386.
* In the `Makefile` file, make sure we always install the symlink for "luajit"
  even for alpha or beta versions.
* Applied a patch to fix DragonFlyBSD compatibility. Note: this is not an
  officially supported target.
* feature: jit.dump: output Lua source location after every BC.
* feature: added internal memory-buffer-based trace entry/exit/start-recording
  event logging, mainly for debugging bugs in the JIT compiler. it requires
  `-DLUA_USE_TRACE_LOGS` when building LuaJIT.
* feature: save `g->jit_base` to `g->saved_jit_base` before `lj_err_throw`
  clears `g->jit_base` which makes it impossible to get Lua backtrace in such
  states.

[Back to TOC](#table-of-contents)

# Copyright & License

LuaJIT is a Just-In-Time (JIT) compiler for the Lua programming language.

Project Homepage: http://luajit.org/

LuaJIT is Copyright (C) 2005-2019 Mike Pall.

Additional patches for OpenResty are copyrighted by Yichun Zhang and OpenResty
Inc.:

Copyright (C) 2017-2019 Yichun Zhang. All rights reserved.

Copyright (C) 2017-2019 OpenResty Inc. All rights reserved.

LuaJIT is free software, released under the MIT license.
See full Copyright Notice in the COPYRIGHT file or in luajit.h.

Documentation for the official LuaJIT is available in HTML format.
Please point your favorite browser to:

    doc/luajit.html

[Back to TOC](#table-of-contents)
