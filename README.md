# Modern C++ Template

A small **CMake 4.4 / C++26** starting point with a reproducible Nix development
environment, real library/application/header-only examples, and installable CMake
packages. Dependencies use **CPM.cmake 0.43.1**; tests use **Catch2 3.11.0**.

## Requirements

- CMake **4.4 or newer** and **Ninja**.
- A compiler accepting C++26 mode and the library features your project uses.
- Network access for uncached Nix packages or CPM dependencies.

C++26 is required without compiler extensions. The template does not silently
fall back to C++23/20. Accepting a language mode does not mean a compiler and its
standard library implement every feature in the standard.

Exceptions and the platform-default runtime remain enabled. A static library is
not a fully static executable: this template does not force static libc, static
MSVC CRT, or disable exceptions.

## Quick start

With [Nix](https://nixos.org/download/) and flakes enabled:

```bash
nix develop --no-update-lock-file
cmake -G Ninja -S . -B build-nix -DProject_ENABLE_CLANG_TIDY=ON
cmake --build build-nix --parallel
ctest --test-dir build-nix --output-on-failure
cmake --build build-nix --target all_verify_header_sets --parallel
```

Without Nix, use the same CMake commands with a suitable native toolchain and a
separate build directory. On Windows, run them from an MSVC developer shell.
Ninja is a single-configuration generator: choose `-DCMAKE_BUILD_TYPE=Release`
at configure time, rather than relying on `--config Release` to change a Debug
build.

## Project modes

The stable library target is `Project`, with alias **`Project::Project`**, in all
modes. Tests and the application link that same target; there is no duplicate
library compiled only for tests.

| Mode | Configure options | Output |
| --- | --- | --- |
| Static library (default) | `-DBUILD_SHARED_LIBS=OFF` | Compiled library |
| Shared library | `-DBUILD_SHARED_LIBS=ON` | Shared library with explicit exported API |
| Application | `-DProject_BUILD_EXECUTABLE=ON` | Library plus `Project_app`, installed as `project` |
| Header-only library | `-DProject_BUILD_HEADERS_ONLY=ON` | INTERFACE target and inline implementation |

Application and header-only options can be combined. `BUILD_SHARED_LIBS` has no
binary to control in header-only mode. Header-only still uses CMake to generate
its configuration/version headers; these are installed with the public headers.

```bash
cmake -G Ninja -S . -B build-app -DProject_BUILD_EXECUTABLE=ON
cmake --build build-app --parallel
./build-app/bin/Debug/project

cmake -G Ninja -S . -B build-header -DProject_BUILD_HEADERS_ONLY=ON
cmake --build build-header --parallel
ctest --test-dir build-header --output-on-failure
```

`Project_ENABLE_UNIT_TESTING` defaults ON for a top-level build and OFF when the
project is embedded with `add_subdirectory`. To build without Catch2 or a network
download of its bootstrap/dependencies:

```bash
cmake -G Ninja -S . -B build-library -DProject_ENABLE_UNIT_TESTING=OFF
cmake --build build-library --parallel
```

## Turning the template into your project

1. Change `project(Project VERSION 0.1.0 ...)` in `CMakeLists.txt`.
2. Rename `include/project/` and update source include paths, sample namespaces,
   and generated-macro references such as `PROJECT_EXPORT` and
   `PROJECT_HEADER_ONLY`. Generated headers use the lowercase project name;
   macro prefixes use its uppercase C identifier.
3. Update `cmake/SourcesAndHeaders.cmake`. It lists implementation files, public
   and private headers, application entrypoints, tests, and the consumer example.
4. Update `Project_...` options and `Project::Project` references in examples,
   `test/verify.cmake`, `test/consumer`, workflows, and documentation. Adjust the
   package version request and installed application name in the verification
   examples. `make PROJECT_NAME=YourProject ...` selects the corresponding options.
5. Replace the example API/tests and the release archive name with your own.

The generic filename **`cmake/ProjectConfig.cmake.in` does not need renaming**:
the generated config and target names follow `project(...)` automatically.

Compiled libraries always generate an export header. Mark public APIs with the
export macro, as the example does; visibility is hidden otherwise. This supports
Windows shared libraries without relying on automatic symbol export. The old
`USE_ALT_NAMES`, `VERBOSE_OUTPUT`, and `GENERATE_EXPORT_HEADER` options are removed.
Use CMake's `--log-level=VERBOSE` for verbose configuration.

## Dependencies

To add a dependency, include `cmake/CPM.cmake` in the root file and use its target:

```cmake
include(cmake/CPM.cmake)
CPMAddPackage(
  NAME example_dependency
  GITHUB_REPOSITORY owner/repository
  VERSION 1.2.3
  SYSTEM YES
)
target_link_libraries(${PROJECT_NAME} PRIVATE example_dependency::example_dependency)
```

Use PUBLIC/INTERFACE instead of PRIVATE when the public API requires it. Such
exported dependencies also need matching `find_dependency(...)` calls in the
package config. Do not copy dependency include paths or warning flags manually.

The CPM bootstrap is downloaded with a checked SHA256. Without an explicit
`CPM_SOURCE_CACHE`, dependencies stay in the build directory. An optional shared
cache (`-DCPM_SOURCE_CACHE="$HOME/.cache/CPM"`) can save downloads across build
directories; CI uses one. Disabling tests avoids the Catch2/CPM download unless
you add another dependency yourself.

## Install and consume

```bash
cmake --install build-nix --prefix "$PWD/install"
```

A separate project can use:

```cmake
find_package(Project 0.1 CONFIG REQUIRED)
add_executable(example main.cpp)
target_link_libraries(example PRIVATE Project::Project)
```

Pass the installation prefix in `CMAKE_PREFIX_PATH`. The imported target provides
headers and C++26, but not project warning flags or analysis settings. Relative
GNUInstallDirs layouts can be relocated, including to paths with spaces. When
using a shared library on Windows, place the installed DLL beside the executable
or include its `bin` directory in PATH.

Version matching uses **SemanticVersion**: 0.x packages require the same minor
version; 1.x and later require the same major. In either case the installed
version must meet the requested minimum. Header-only package versions are
architecture-independent; compiled packages retain CMake's architecture check.

The installed sample application has a relative library RPATH on Linux/macOS.
This does not bundle the system runtime or Nix store dependencies. Native
installation packages are not automatically standalone distribution archives.

## Development tools

| Option | Default | Purpose |
| --- | --- | --- |
| `Project_BUILD_EXECUTABLE` | OFF | Add the sample application |
| `Project_BUILD_HEADERS_ONLY` | OFF | Use an INTERFACE library |
| `Project_ENABLE_UNIT_TESTING` | Top-level only | Build Catch2 tests |
| `Project_WARNINGS_AS_ERRORS` | OFF | Enforce warnings on project compilation |
| `Project_ENABLE_CLANG_TIDY` | OFF | Analyze library/application sources |
| `Project_ENABLE_CPPCHECK` | OFF | Analyze library/application sources |
| `Project_ENABLE_CCACHE` | ON | Use ccache if no launcher was explicitly set |
| `Project_ENABLE_CODE_COVERAGE` | OFF | Instrument owned targets with GCC/Clang |
| `Project_ENABLE_LTO` | OFF | Enable supported interprocedural optimization |
| `Project_ENABLE_ASAN` | OFF | Enable AddressSanitizer |
| `Project_ENABLE_DOXYGEN` | OFF | Add `doxygen-docs` |

Warnings and analyzers do not propagate to consumers or third-party targets.
Catch2 macros are not included in the integrated clang-tidy checks. Since an
INTERFACE library has no compilation unit, `test/verify.cmake` also runs a direct
clang-tidy check of the public sample header when lint is enabled.

Use `CLANGTIDY_EXTRA_ARGS` for additional semicolon-separated arguments.
`CMAKE_CXX_COMPILER_LAUNCHER` (including an explicitly empty value) takes priority
over automatic ccache; ccache does not wrap links. The `clang-format` target
covers all owned sample/test/consumer files, including disabled targets, but not
dependencies or generated headers. Override `Project_CLANG_FORMAT_BINARY` to
select a formatter compatible with `.clang-format`.

Coverage follows the chosen configuration's optimization settings, rather than
silently forcing `-O0`. In particular, Nix hardening can add optimization even in
a Debug build. Instrumented compiled libraries export their coverage/sanitizer
link requirements where applicable. ASan requires a compatible dynamic runtime;
do not combine it with a fully static executable link.

The Makefile is optional and does not delete existing build trees:

```bash
make test BUILD_DIR=build-nix
make headers BUILD_DIR=build-nix
make coverage BUILD_DIR=build-nix
make docs BUILD_DIR=build-nix
make format BUILD_DIR=build-nix
make install BUILD_DIR=build-nix INSTALL_LOCATION="$HOME/.local"
```

Coverage and documentation use separate build directories. Doxygen output is
under the selected build tree, not in the source tree.

## Locked Nix environment

`flake.nix` supports native **x86_64/aarch64 Linux** and **Apple Silicon macOS**.
The pinned nixpkgs has dropped Intel macOS support; adding an x86_64-darwin
attribute would not make it usable. Linux uses the locked GCC stdenv; macOS
uses the locked Clang stdenv. It also
provides CMake, Ninja, Git, pkg-config, ccache, clang-tools, cppcheck, Doxygen,
Graphviz, gcovr, GNU Make, and actionlint. Windows uses a native MSVC environment,
not Nix. These are native environments, not cross-compilers.

Linux static libc is available through a `LIBRARY_PATH` fallback, without
shadowing shared libc during normal compiler checks. It does not change the
template's default runtime linkage.

```bash
nix flake check --no-update-lock-file --all-systems --no-build
nix fmt -- --check flake.nix
# An intentional toolchain update; review and commit the resulting lock diff:
nix flake update nixpkgs
```

Flake evaluation for a system is not proof of a successful build on that system.
Always distinguish compilation, analyzer compatibility, tests, and installation
checks; a compiler succeeding does not establish that clang-tidy can analyze
every use of its standard library.

## Containers

The development image uses `flake.nix` / `flake.lock`, not a second apt/pip C++
toolchain. Architecture-specific rolling `nixpkgs/nix-flakes` bases are selected
for amd64 and arm64. Only the flake metadata enters the build context; sources
are mounted at runtime. The image preloads the dev shell and runs commands via
`nix develop --no-update-lock-file --command`.

```bash
docker build --pull -t cpp-template-dev .
docker run --rm -it \
  --mount type=bind,source="$PWD",target=/workspace \
  cpp-template-dev
```

Inside the shell, build into `build-container`, not a host-toolchain build tree.
CPM uses default per-build storage; the source bind mount preserves the build
and downloaded dependencies without a separate cache variable or volume.
Container commands run as root by default, so Linux bind mounts can contain
root-owned build files. Applications with permission-sensitive tests should run
those tests as an ordinary user.

On Apple Silicon, Apple's [`container`](https://github.com/apple/container) can
build the same native Linux arm64 image:

```bash
container system start --enable-kernel-install
container build --platform linux/arm64 --build-arg TARGETARCH=arm64 \
  --pull -t cpp-template-dev .
container run --rm -it --cpus 4 --memory 8G \
  --mount type=bind,source="$PWD",target=/workspace \
  cpp-template-dev
```

Apple container 1.5.0 requires the explicit `TARGETARCH`; `--platform` alone does
not populate it. Unlike `run`, `exec` does not invoke the image entrypoint: use
`nix develop --no-update-lock-file --command ...` explicitly when executing a
command in an existing container.

## Verification and CI

Run the same build/install checks used by CI inside the selected toolchain:

```bash
cmake -DMODE=static -DENABLE_LINT=ON -P test/verify.cmake
cmake -DMODE=shared -DENABLE_LINT=ON -P test/verify.cmake
cmake -DMODE=executable -DENABLE_LINT=ON -P test/verify.cmake
cmake -DMODE=header-only -DENABLE_LINT=ON -P test/verify.cmake
```

Each mode builds with warnings-as-errors, runs tests and header checks, installs,
moves the prefix to a path with spaces, and compiles/runs a real installed-package
consumer. The consumer requests C++23, verifying that the imported target raises
its requirement to C++26 without exporting warning flags. Shared-library checks
also run the relocated installed application. `BUILD_DIR`, `CONFIG`, and
`ENABLE_COVERAGE` customize the driver.

Ubuntu and `macos-latest` workflows use the locked Nix shell. The current
`macos-latest` runner is Apple Silicon; its OS image rolls forward while the
compiler and build tools remain pinned by the flake lock. Windows uses MSVC with CMake
4.4+ and Ninja. CI covers the four configurations above; Ubuntu also emits a
GCC/gcovr coverage report. Codecov upload is optional/non-fatal and can use the
repository's `CODECOV_TOKEN` secret. Toolchain-specific failures must not be
hidden by globally disabling diagnostics.

Tag builds reuse those checks before publishing **source archives** using
`git archive`, excluding caches, build products, and `.git` credentials. Replace
the archive name in `.github/workflows/release.yml` when creating your project.

## Contributing and license

See [CONTRIBUTING.md](CONTRIBUTING.md) and
[PULL_REQUEST_TEMPLATE.md](PULL_REQUEST_TEMPLATE.md). The template follows
[SemVer](https://semver.org/) and is licensed under the [Unlicense](LICENSE).
Originally created by **Filip-Ioan Dutescu** ([filipdutescu](https://github.com/filipdutescu)).
