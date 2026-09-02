# UnderC 1.5.0

UnderC is an interactive C and C++ interpreter by Steve Donovan (https://github.com/stevedonovan).
I hereby want to thank the initial developers for their amazing work!
It parses source, compiles it to an internal p-code instruction stream, and executes that
stream immediately. Version 1.5.0 builds with current GCC/Clang and MSVC
toolchains, CMake, libffi, and 64-bit hosts.
Previous modifications where done by https://github.com/antirez

Optional Libffi can be downloaded from github.com/libffi/libffi or https://github.com/mathematechde/libffi for cmake support.

1.3.0-current modifications where done by Louis Höfler (https://github.com/mathematechde, www.mathematech.de)

See LICENSE for license.

## Language support

UnderC interprets its maintained C++98-era language dialect with extensions
and builds with GNU C++98. Files ending in `.c` activate C mode, which applies C
tag-name and enum behavior through the shared parser.

Supported C++98-era facilities include classes and structs, inheritance,
virtual functions, constructors and destructors, overloads, references,
namespaces, exceptions, RTTI-style casts, and templates.
UnderC also provides `typeof`, `__declare`, and `__lambda` extensions and
supports member templates. Standard scalar compatibility includes `true`,
`false`, `NULL`, `signed` integer spellings, a two-byte `wchar_t` alias, and
the alternative operator tokens (`and`, `or`, `not`, `bitand`, `bitor`,
`xor`, `compl`, and their assignment/equality forms). Other ISO C/C++98 words
remain reserved even when their semantics are outside this dialect.

## Features

- Interactive statement and expression evaluation with type-aware result
  display.
- Automatic interactive loading of the bundled class library from
  `$UC_HOME/uclresource/defs.h`, with a working-directory `defs.h` available
  as a local override.
- Source-file loading, unloading, cleaning, and reloading.
- Path-qualified source loads derive synthetic module-initializer names from
  the basename, without retaining the final directory separator.
- C and C++ declarations, functions, overloading, default arguments, classes,
  inheritance, access control, virtual methods, constructors, and destructors.
- ISO boolean/null constants, signed integer spellings, `wchar_t`
  compatibility, and alternative operator tokens.
- Namespaces, `using` declarations, typedefs, enums, references, pointers,
  arrays, operator overloading, templates, exceptions, and RTTI-style casts.
- An internal p-code compiler and virtual machine, with built-in staged
  bytecode optimization, optional one-instruction function inlining, and
  disassembly.
- A preprocessor supporting includes, macros, conditional compilation,
  `#warning`, `#error`, pragmas, and command aliases.
- Dynamic-library loading through `#lib` or `#pragma dlink`; the supported
  portable import surface is unmangled `extern "C"` functions.
- Built-in console, formatted and file I/O; string and memory operations;
  mathematics; allocation; environment and shell access; exit handlers;
  process pipes; file-access checks; and interpreter-control functions.
- A compact bundled library with strings, streams, containers, regular
  expressions, timers, exception helpers, and persistence helpers.
- A separated header layout: native consumer APIs live under
  `include/underc`, private native build headers remain under `include`, and
  the interpreted pocket STL/runtime library lives under
  `include/underc/uclstl` and is searched there by default.
- The native pocket-string API supports direct `const char *`
  comparison, equality, and inequality overloads and treats a null C-string
  constructor argument as an empty string.
- Interactive inspection of variables, functions, types, modules, and stack
  frames, plus disassembly, breakpoints, stepping, function tracing, pointer
  checking, and array-range checking.
- A C-compatible embedding API for live, two-way bindings between host scalar
  variables and interpreted names, plus reflection and native import APIs.
- Checked scalar native-call argument-slot marshalling for fixed and variadic
  libffi calls, including bool and enum constants in multi-argument calls.
- Aggregate return values from imported natives, resolved through the import
  scheme rather than through uninitialized function metadata.
- Whole-object value semantics: assignment between plain structs and return of
  a plain struct by value copy in the correct direction.
- Word-accurate local frame allocation: every local occupies its own slot,
  including locals narrower than a VM word and a scalar declared after an
  array.
- `new T[n]` constructs and `delete[]` destroys every element, so dynamic
  arrays of class type hold fully initialized objects, and the hidden
  method-table slot reserved by `new` matches the width the engine reads.
- Pocket-STL containers of strings, including `vector<string>` at any size,
  `std::map` copy construction, assignment, and return by value, and nested
  instantiations such as `map<string, vector<string> >`.
- Interpreted exception handling with pointer-width handler and thrown-object
  storage, innermost-first catch matching, catch-by-base, and `catch(...)`.
- A generated, address-free UCRI self-import manifest that resolves symbols in
  the running process and remains valid with PIE, ASLR, and 64-bit pointers.

## Requirements and build

The source tree now builds the interpreter engine as an installable library and
the command-line interface as a separate consumer. It requires CMake 3.16 or
newer, a compiler with GNU C++98 support, and libffi on every host whose
native-call path needs it. Readline and curses
development packages are used by default on Unix; on Windows `UCL_USE_READLINE`
defaults to `OFF` and neither package is needed. GNU Bison (with its `yacc`
mode) is required only when the pre-generated parser under `src/gen` is absent;
a source tree that ships those files builds without bison or yacc installed.

Build, install, and consume the default static library with:

```sh
cmake -S src -B build-lib -DCMAKE_INSTALL_PREFIX=/tmp/underc
cmake --build build-lib
cmake --build build-lib --target selfimp
cmake --build build-lib --target install
cmake -S cli -B build-cli -DCMAKE_PREFIX_PATH=/tmp/underc \
  -DCMAKE_INSTALL_PREFIX=/tmp/underc
cmake --build build-cli
cmake --build build-cli --target install
```

This installs `libunderc`, its CMake package support, the consumer API in
`include/underc`, and the interpreted library in `include/underc/uclstl`, then
installs `ucc`. Compiler-private headers from the source tree are not
installed. To build and consume the shared library instead:

```sh
cmake -S src -B build-lib-shared -DUCL_SHARED=ON \
  -DCMAKE_INSTALL_PREFIX=/tmp/undercshared
cmake --build build-lib-shared
cmake --build build-lib-shared --target selfimp
cmake --build build-lib-shared --target install
cmake -S cli -B build-cli-shared -DUCC_SHARED=ON \
  -DCMAKE_PREFIX_PATH=/tmp/undercshared \
  -DCMAKE_INSTALL_PREFIX=/tmp/undercshared
cmake --build build-cli-shared
cmake --build build-cli-shared --target install
```

The explicit `selfimp` target uses `nm` and `awk` to generate the UCRI symbol
manifest at `lib/uclr/self.imp`. Set the `UNDERC_SELFIMP_OUTPUT` CMake cache
variable to choose another output path. The manifest contains symbol names,
not link-time addresses; UnderC resolves them in the current process at
runtime. Including `ucri.h` always autoloads the manifest from
`$UC_HOME/lib/uclr/self.imp`. The install step copies a generated manifest to
`lib/uclr` when it exists.

`UCL_` options and macros belong to the library; `UCC_` options and macros
belong to the command-line program. `UCL_SHARED` builds the shared-library
variant. To build the library without readline:

```sh
cmake -S src -B build-lib -DUCL_USE_READLINE=OFF
cmake --build build-lib
```

Native calls use libffi by default, providing ABI-correct scalar, pointer,
reference, floating-point, variadic, and dynamically sized fixed argument
lists. Native function pointers exported from interpreted functions are also
libffi closures and support free functions, methods, floating-point values,
argument lists beyond the register limit, and recursive host/interpreter
calls. Plain non-union aggregates use generated libffi structure descriptions
for arguments and returns. Non-trivial C++ objects and aggregates containing
bit-fields remain pointer/reference-only.

A prebuilt libffi carries no architecture marker that `find_library`
inspects, so CMake link-tests the candidate before accepting it. A libffi that
cannot be linked by the active toolchain — an x64 package offered to a 32-bit
build, say — is reported during configuration instead of surfacing as
unresolved `ffi_*` externals in the first executable that links. On a 64-bit
host this is a configuration error, because there is no built-in dispatcher to
fall back on; on a 32-bit host the build warns and uses the built-in 32-bit
native dispatcher, which handles scalar, pointer, and floating-point calls and
interpreted callbacks but not variadic natives or by-value aggregates.

`UCL_STRICT_CONVERSIONS` enables migration-oriented conversion warnings, and
`UCL_SANITIZERS` enables AddressSanitizer and UndefinedBehaviorSanitizer on
GCC/Clang builds.

### Windows (MSVC / nmake)

`build-cmake-vs2026-nmake-release.bat` in the repository root configures and
builds the interpreter library with a Visual Studio toolchain and the
`NMake Makefiles` generator:

```bat
cmake -G "NMake Makefiles" -B out-cmake-vs2026-nmake-x64r -S ./src ^
  -DCMAKE_PREFIX_PATH="<libffi-prefix>" ^
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="%APPDATA%"
cmake --build out-cmake-vs2026-nmake-x64r
cmake --build out-cmake-vs2026-nmake-x64r --target install
```

The Windows build does not use `pkg-config`. libffi is located with
`find_path`/`find_library` from `CMAKE_PREFIX_PATH`, which must point at a
prebuilt libffi that provides `ffi.h` and an `ffi` or `libffi` import library.
`UCL_USE_READLINE` defaults to `OFF` here because GNU readline and curses are
not part of a stock MSVC toolchain; the interpreter uses its plain console
line editor instead. The `selfimp` target requires `nm` and `awk` and is not
available in this configuration, so the generated `lib/uclr/self.imp` manifest
must be produced on a POSIX host if it is needed.

The `NMake Makefiles` generator takes its compiler from the environment, so
the developer prompt that runs the build chooses the target: an x64 prompt
produces a 64-bit interpreter and an x86 prompt a 32-bit one. Both are
supported, and `CMAKE_PREFIX_PATH` must point at a libffi of the same
architecture.

Sources that previously assumed 32-bit x86 MSVC have been made portable: the
fake-iostream library now streams
64-bit `VMWord`/frame-slot values, `Type::alignment()` uses standard `alignof`,
the 32-bit inline-assembler native-call thunk and x87 FP-exception fiddle are
restricted to `_M_IX86` (x64 uses the libffi path and the portable fallback),
and the exported embedding API in `ucembed.h` carries consistent DLL linkage.
Local UnderC script headers (`src/eh.h`, `src/winuser.h`) that shadowed the
real Windows SDK headers were removed from the compiler include path; the
canonical interpreted copies are under `include/underc/uclstl`. At runtime the
prebuilt `ffi.dll` must be on `PATH`.

The 32-bit path is maintained rather than merely retained. Its generated
callback stubs are placed in executable pages instead of on the no-execute C++
heap, their argument block is initialized before the interpreter reads an
argument count from it, and aggregate layout follows the host's own alignment
of a `double` inside a struct.

### VM word size

A 32-bit host runs a 32-bit ABI and a 64-bit host a 64-bit one. CMake detects
the host pointer size with `CMAKE_SIZEOF_VOID_P` and uses that as the VM word
size; `underc/vm_types.h` derives the same answer from the host when no build
system supplies `UNDERC_VM_BITS`, so a consumer that only has the installed
headers never has to restate the ABI. The selected value is reported during
configuration. It may be set explicitly to 16, 32, or 64 bits:

```sh
cmake -S src -B build-lib -DUNDERC_VM_BITS=32
cmake --build build-lib
```

`UNDERC_VM_BITS` controls the signed and unsigned VM word types, execution
stack slots, instruction operands, pointer transport, constants, symbol
payloads, switch tables, function-frame offsets, argument blocks, and the
native-call bridge. Floating-point values consume as many VM slots as their
representation requires.

Runnable builds require a VM word at least as wide as a host pointer. CMake
rejects narrower selections before compilation. A narrower configuration can
be retained solely as a non-runnable compile check with
`-DUCL_COMPILE_ONLY_NARROW_VM=ON`; `uc_init` refuses to start such a build.

By default, interpreted object layout follows the compiler host ABI: `int` and
ordinary enums use the host `int` width, `long` uses the host `long` width, and
pointers use the host pointer width. VM evaluation slots remain
`UNDERC_VM_BITS` wide. Class fields use their natural type alignment capped by
the active packing value; aggregate sizes are rounded to their effective
alignment. That packing value is the widest fundamental alignment of the host
ABI, not the pointer width: on 32-bit MSVC a `double` is 8-aligned inside an
aggregate although a pointer is only 4-aligned, and the alignment is measured
from the host rather than assumed, because the i386 System V ABI aligns the
same `double` to 4. Host-comparison regressions verify mixed `char`, `int`,
`double`, and pointer layouts and pass interpreted aggregate pointers to
native code.

The VM-width object model can be selected with:

```sh
cmake -S src -B build-lib -DUCL_DISABLE_NATIVE_ABI=ON
```

In that mode, `int`, ordinary enums, and `long` objects use the configured VM
word width.

The parser sources `tparser.cpp` and `tparser.h` are generated with bison/yacc
from `src/build/parser.y` and cached in `src/gen`. When those cached files are
present CMake uses them verbatim and does not search for or require bison; when
they are absent CMake runs bison/yacc to regenerate them into `src/gen`, so a
later checkout can reuse them. This allows compiling on systems that have no
bison or yacc installed. Delete `src/gen` to force regeneration. The original
code requires GNU extensions and is therefore compiled as GNU C++98. Non-debug
builds use the project’s `-O1` optimization level.

### Tests

The permanent runtime regression sources live under `regressiontests/`. A
test runner is built with the library when `BUILD_TESTING` is enabled (the
CMake default), so the migration suite can be run without first installing
the separate CLI:

```sh
cmake -S src -B build-test -DUCL_USE_READLINE=OFF -DBUILD_TESTING=ON
cmake --build build-test
ctest --test-dir build-test --output-on-failure
```

Use `-DUCL_DISABLE_NATIVE_ABI=ON` in a second build directory to exercise the
VM-width object model. The sources can also be passed directly to an installed
`ucc` executable. The `host-abi-width` test compiles against the installed
public headers alone, without the library's own compile definitions, and
checks that the VM word and the aggregate alignment rule match the host.

### Bytecode optimization

Use `-O0`, `-O1`, `-O2`, or `-O3` before the source-file argument to select
the bytecode optimization level. The default is `-O0`.

- `-O0` disables bytecode optimization.
- `-O1` applies local stack and redundant-operation peepholes.
- `-O2` adds integer constant folding and unary simplification.
- `-O3` adds algebraic strength reduction, jump threading, redundant-jump
  removal, and one-instruction function inlining.

The optimizer is built into UnderC and has no additional runtime dependency.
It follows the staged peephole, constant-folding, and control-flow reduction
approach used by V8's interpreter while adapting the passes to UnderC's
stack-based p-code and stable instruction-offset requirements.

### Embedding

Include `underc/ucdl.h`, initialize the interpreter with `uc_init`, and call
`uc_bind_variable` to expose host storage as an interpreted global variable.
Bindings are live and two-way: interpreted assignments immediately update the
host object. The host object must remain alive until the interpreter no longer
uses the binding.

`uc_bind_variable` accepts a name, a `uc_variable_type`, and the host address,
and returns a `uc_status`. Supported types are `bool`, signed and unsigned
`char`, `short`, `int`, and `long`, plus `float` and `double`. Names must be
valid C identifiers and must not already exist in the global context.

The standalone consumer in `embed/` demonstrates both execution paths. First,
`main.cpp` binds host `count` and `multiplier` variables and changes them by
calling `uc_exec` directly. It then initializes an interpreted string, loads
`embed/ucload.cpp` with `uc_load`, and prints the value after the loaded
function changes it. `uc_load` accepts a `const char *` path and returns
nonzero when the source loaded successfully. Build the example against an
installed library:

```sh
cmake -S src -B build-lib -DCMAKE_INSTALL_PREFIX=/tmp/underc
cmake --build build-lib --target install
cmake -S embed -B build-embed -DCMAKE_PREFIX_PATH=/tmp/underc
cmake --build build-embed
UC_HOME="$PWD" build-embed/underc-embed
```

The example prints the initial and changed numeric values, followed by
`Hello from underc`.

### Examples

The `examples/` directory contains small applications that run directly with
the command-line interpreter. The calculator accepts one quoted mathematical
expression and prints its value:

```sh
UC_HOME="$PWD" build-cli/ucc examples/uccalc.cpp "2 * (3 + 4)"
```

`uccalc.cpp` supports floating-point `+`, `-`, `*`, `/`, right-associative
`^`, parentheses, and unary signs. `tkgui.c` demonstrates dynamic Tcl/Tk
imports by opening a window with a button that closes it:

```sh
UC_HOME="$PWD" build-cli/ucc examples/tkgui.c
```

The GUI example requires Tcl and Tk shared libraries discoverable as
`libtcl.so` and `libtk.so`, plus a graphical display.

Native-import sources live in `examples/import/`. Native imports
have two parts: a host compiler produces a `.so` or `.dll`, and UnderC parses
the matching declarations in a header bracketed by `#lib`. The native library
must export the exact symbols requested by those declarations. C++ imports are
ABI-specific, so build the library with a compiler compatible with the symbol
mangling expected by the UnderC build.

On Linux, the following commands build the two libraries used by `import1.h`,
show their exported symbols, and run the value-import smoke example. Run them
from the repository root:

```sh
g++ -std=gnu++98 -fPIC -fkeep-inline-functions -shared \
  examples/import/mstring.cpp -o examples/import/libmstring.so
g++ -std=gnu++98 -fPIC -fkeep-inline-functions -shared \
  examples/import/import1.cpp examples/import/mstring.cpp \
  -o examples/import/libimport1.so

nm -D --defined-only examples/import/libimport1.so | \
  grep -E '_Z3addii|_Z3sumdd|FatString'
nm -D --defined-only examples/import/libimport1.so | c++filt | \
  grep -E 'add\(|sum\(|FatString'

UC_HOME="$PWD" build-cli/ucc examples/import/import1-run.cpp
```

The first `nm` command displays the actual mangled ELF symbols, including
`_Z3addii` and `_Z3sumdd`. Piping through `c++filt` displays their readable
forms, `add(int, int)` and `sum(double, double)`. The program should print
`add=42 sum-ok=1`. If UnderC reports `cannot link to`, use `nm` to check that
the requested mangled symbol is present in the library.

Other Linux examples can be built in the same way:

```sh
g++ -std=gnu++98 -fPIC -fkeep-inline-functions -shared \
  examples/import/import2.cpp -o examples/import/libimport2.so
g++ -std=gnu++98 -fPIC -fkeep-inline-functions -shared \
  examples/import/import3.cpp -o examples/import/libimport3.so
g++ -std=gnu++98 -fPIC -fkeep-inline-functions -shared \
  examples/import/import4.cpp -o examples/import/libimport4.so
g++ -std=gnu++98 -fPIC -fkeep-inline-functions -shared \
  examples/import/import5.cpp -o examples/import/libimport5.so
nm -D --defined-only examples/import/libimport5.so | c++filt
```

With the Microsoft command-line compiler, open a Developer Command Prompt and
run these commands from the repository root. The DLLs are written to the root
because the Windows branches in `mstring.h` and `import1.h` load them by bare
filename:

```bat
cl /nologo /EHsc /LD examples\import\mstring.cpp /link /OUT:mstring.dll
cl /nologo /EHsc /LD examples\import\import1.cpp ^
  examples\import\mstring.cpp /link /OUT:import1.dll
dumpbin /exports import1.dll
set UC_HOME=%CD%
build-cli\ucc.exe examples\import\import1-run.cpp
```

MinGW uses the same source files and can create DLLs with `g++`:

```sh
g++ -std=gnu++98 -fkeep-inline-functions -shared \
  examples/import/mstring.cpp -o mstring.dll
g++ -std=gnu++98 -fkeep-inline-functions -shared \
  examples/import/import1.cpp examples/import/mstring.cpp -o import1.dll
nm -g --defined-only import1.dll | c++filt
```

The other `.cpp` files in that directory are native shared-library sources,
not standalone interpreted programs. `-fkeep-inline-functions` retains the
inline symbols described by their interpreter-side class declarations.

## Running

Set `UC_HOME` to the repository root so UnderC can find its default
`include/underc/uclstl`, `lib/`, and `uclresource/` trees:

```sh
UC_HOME="$PWD" build-cli/ucc
UC_HOME="$PWD" build-cli/ucc program.cpp argument1 argument2
```

With no source-file argument, `ucc` starts interactively. It first checks the
working directory for an optional `defs.h`; otherwise it loads
`$UC_HOME/uclresource/defs.h`, which imports `classlib.h` and the `std`
namespace. Interactive and command-line help are loaded from the same resource
directory.

Useful command-line options include:

- `-H path`: override `UC_HOME`.
- `-I path`: add an include directory.
- `-D name=value`: define a macro.
- `-r path`: change directory before running.
- `-i`: force interactive mode.
- `-P`: enable pointer checking.
- `-R`: enable array range checking.
- `-F`: attempt small-function inlining.
- `-T`: prefer typedef names in diagnostics.
- `-W`: suppress dynamic-link warnings.
- `-v`: print the version.
- `--help`: show command-line help.

At the interactive prompt, `#help` displays all commands. The principal ones
are `#l file` (load or reload), `#r args...` (run the loaded `main`), `#q`
(quit), `#ql` (quit and write a dated log), `#cd`/`#pwd`, `#x command`
(execute a shell command), and `#lib library [import-file]` (begin importing a
native library; use bare `#lib` to finish). `#pragma dlink` is the source-level
equivalent of `#lib`.

Inspection and debugging commands include `#v`/`#d`/`#lv` (symbols and
variables), `#types`, `#funs`, `#mod`, `#u` (disassemble), `#b`/`#bs`/`#gt`
(breakpoints), `#ff` (select a frame), `#s` (stop), and `#rm` (remove a symbol
or program). `#alias` defines command aliases and `#mc` clears macros and the
global namespace.

`#opt` accepts option letters followed by `+` or `-`: `o` automatic
disassembly, `t` function tracing, `v` verbose mode, `s` strict conversions,
`p` pointer checks, `a` access control, `C` C mode, `T` typedef names in
diagnostics, and `L` suppressed link errors.

### Bundled interpreted library

The default environment exposes common math, conversion, string, memory,
formatted-I/O, file-I/O, process-pipe, and allocation functions. Interpreted
programs call `popen` and `pclose` portably; the host bridge uses POSIX
`popen`/`pclose` on Linux and `_popen`/`_pclose` on Windows. The bundled
`stdio.h` defines `SEEK_SET`, `SEEK_CUR`, and `SEEK_END`; `stdlib.h` exposes
`getenv`, `system`, `_gcvt`, and callback-capable `atexit`; `io.h` exposes
`_access` through a portable host bridge; `string.h` defines `size_t` itself
so it can be included on its own; and
`uc_except.h` exposes `RangeError`. The bundled headers also add compact
`string`, stream, `list`, `vector`, and `map` implementations, regular
expressions, directory traversal, timers, exception helpers, persistence and
reflection helpers. These are compact implementations for UnderC programs,
not a complete or conforming standard library. See
[LANGUAGE.md](LANGUAGE.md) for the precise language boundary.

Native C functions can be imported after `#lib` by declaring `extern "C"`
prototypes; the examples in `examples/import/` show the declarations and
import files. The public `<underc/ucdl.h>` API provides
interpreter lifecycle, evaluation, imports, compilation, and live variable
binding; `<underc/ucri.h>` exposes lower-level symbols, types, calls, tracing,
and persistence.
Its instruction record uses a pointer-width operand and matches runtime
instructions in runnable builds; it no longer exposes a packed 22-bit operand.
New clients should use `XFunction::instruction_count()` and
`XFunction::instruction_at()` to obtain versioned `XInstructionInfo`
snapshots instead of casting runtime instruction storage.
UCRI self-import uses the generated `UC3 AUTO` manifest, with runtime ABI
selection and symbol resolution instead of fixed executable addresses.

## Project layout

- `src/`: installable interpreter library, VM, debugger, and library
  CMake/package files.
- `src/build/`: parser grammar, self-import generator, and build support.
- `src/gen/`: cached bison/yacc parser output (`tparser.cpp`, `tparser.h`) used
  when present so builds need no bison or yacc.
- `cli/`: standalone `ucc` command-line front end and consumer CMake project.
- `embed/`: standalone host-variable binding example and consumer CMake project.
- `regressiontests/`: permanent language, VM, ABI, and migration regression
  sources.
- `examples/`: runnable applications and native import examples.
- `include/`: private headers used to compile the native UnderC library.
- `include/underc/`: public headers needed by native library consumers.
- `include/underc/uclstl/`: pocket STL, C library declarations, and support
  headers made available to interpreted programs through the default include
  search path.
- `lib/`: bundled implementation support and generated `uclr/self.imp` manifest.
- `uclresource/`: default interactive definitions and command help text.
- `verify/`: language verification programs.
- `VERSIONS.md`: release history and feature deltas.
- `LANGUAGE.md`: audited interpreted-language scope.
- `MISSMATCH.md`: claims from the old documentation that do not match the
  maintained implementation.
- `LICENSE`: GNU Library General Public License version 2.

## Portability notes

The maintained native-call path uses libffi on Linux x86-64 with GCC/Clang and
on Windows with MSVC. The MSVC/nmake build configures, compiles, and links
the interpreter library and regression executables against a prebuilt libffi.
As of this build the Windows x64 suite passes 44 of 45 tests, both in a
release build and in an AddressSanitizer build. A 32-bit MSVC build with no
matching libffi uses the built-in dispatcher and passes 38 of 39 tests; the
six tests it does not register are the libffi-gated native-call cases. In both
configurations the one remaining failure is
`ucri-self-import`: `#lib $self` resolves symbols with `GetProcAddress` in the
running image and reads the generated `lib/uclr/self.imp` manifest, and neither
the manifest generator (which needs `nm` and an `awk`) nor exported symbols
from a statically linked host executable are available under MSVC. Self-import
is therefore a GCC/Clang facility for now. Portable native integrations should
use unmangled `extern "C"` symbols.

Pointer-width correctness on LLP64 hosts, where `long` is 32 bits, is carried
by the VM word type rather than by `int` or `long`. The hidden virtual-method
table pointer, the try-block marker's handler field, the thrown-object slot,
generated native callback stubs, and the `argv` passed to an interpreted
`main` all use pointer-width storage. Instructions that carry a type operand
store a parser type handle and are decoded through `Parser::AsType()`.

On Windows the bundled C library is imported from `msvcrt.dll`. The stdio
entry points that take a `FILE *` are interpreter built-ins bound to the host
C runtime, so handles from `_get_std_stream()` and `fopen()` are never passed
to a separately loaded runtime.

The bundled `vector` now has regression coverage for construction, growth,
reserve/resize, copy and self-assignment, range assignment, clear, and
destruction. The generic `map` now owns and destroys its nodes, supports empty
insertion, prevents unsafe shallow copying, and has insertion/destruction
coverage.

On non-Windows hosts, native C++ allocations use the host allocator directly;
UnderC's `_new_ex` VMT prefix is reserved for interpreted allocations. Native
calls only receive a hidden object pointer when their registered function is
actually a non-cdecl method.

UnderC is distributed under the terms in [LICENSE](LICENSE).
