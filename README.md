# No-Clip (Geode mod)

[![Build](https://github.com/Fail-Safe/gd-no-clip/actions/workflows/build.yml/badge.svg)](https://github.com/Fail-Safe/gd-no-clip/actions/workflows/build.yml)

A minimal, toggleable "no-clip" mod for Geometry Dash 2.2+ built with Geode.
It provides an in-game toggle and keybind, and hooks PlayLayer::destroyPlayer to
skip death when enabled.

Note: This is not a full collision bypass. For full no-clip, additional hooks on
PlayerObject collision functions are needed. See TODOs in `src/main.cpp`.

## Prerequisites
- Geode Loader installed in GD
- Geode CLI (Rust) installed: `cargo install geode-cli`
- CMake 3.21+
- A C++20 toolchain (Clang on macOS, MSVC on Windows)

Optional for local CMake builds:
- Geode SDK checkout and set `GEODE_SDK` env var pointing to it

## Develop on macOS
You can build and package with the Geode CLI (recommended):

```sh
# From repo root
geode build --config Release
```

Artifacts will be placed in `dist/` as a `.geode` file.

Alternatively, use CMake directly (requires `GEODE_SDK`):
### macOS dev without GD installed (local SDK/binaries)
If you don’t have GD installed locally but still want to compile/package:

```sh
# 1) Install a local Geode SDK and set the path for this repo
geode sdk install .geode-sdk --force
geode sdk set-path .geode-sdk

# 2) Install loader binaries for your platform (macOS, Geode 4.7.0)
geode sdk install-binaries --platform MacOS -v 4.7.0

# 3) Export GEODE_SDK so CMake and Codegen can find headers/binaries
export GEODE_SDK="$PWD/.geode-sdk"

# 4) Build with CLI
geode build --config Release
```

Notes:
- If the CLI asks for a Geode profile path during install, you can point it to any folder you create for development (it won’t launch GD, just stores files).
- Use `--platform MacOS` (capital M, O, S) when installing binaries.


```sh
# Replace path with your local geode SDK path
export GEODE_SDK=~/git/geode
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

## Windows Build (Local)
Prerequisites:
- Visual Studio 2022 (Desktop development with C++) or Build Tools
- Geode CLI (`cargo install geode-cli`)
- Git (and CMake if not using VS's bundled one)

First-time setup & build (PowerShell):
```powershell
git clone https://github.com/Fail-Safe/gd-no-clip.git
cd gd-no-clip
$env:GEODE_SDK = "$PWD/.geode-sdk"
geode sdk install $env:GEODE_SDK
geode sdk install-binaries --platform windows -v 4.7.0
geode build --config Release
```
Package appears in `dist\\*.geode` and is auto-installed if a Geode profile for GD is configured.

Helper scripts (in `scripts/`):
- `scripts/build-windows-release.ps1`
- `scripts/build-windows-release.bat`
- `scripts/build-windows-debug.ps1`
- `scripts/build-windows-debug.bat`

Run script instead of manual commands:
```powershell
pwsh -File scripts/build-windows-release.ps1
```

Using CMake manually (optional):
```powershell
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

Troubleshooting (Windows):
- `No valid loader binary to link to!` -> run `geode sdk install-binaries --platform windows -v 4.7.0` ensuring `$env:GEODE_SDK` points to the repo's `.geode-sdk`.
- Stale errors after moving folders -> delete `build` directory and rebuild.
- Missing `.geode` output -> ensure build ended with `Built target *_PACKAGE`; otherwise run `geode build --config Release`.

### Presets & Ninja (Windows)
This repo includes `CMakePresets.json` with these configure/build presets:
- `windows-release` / `windows-debug`: Multi-config Visual Studio generator.
- `windows-ninja-release` / `windows-ninja-debug`: Single-config Ninja builds (faster incremental).

Using a preset:
```powershell
cmake --preset windows-ninja-release
cmake --build --preset windows-ninja-release
```

VS Code: Run a task named `CMake: Build Preset (windows-ninja-release)` (added in `.vscode/tasks.json`).

Install Ninja (one-time):
```powershell
winget install Ninja-build.Ninja   # or choco install ninja
```
Ensure `ninja` is on PATH, then reconfigure with the Ninja preset.

## CI (GitHub Actions)
This repo includes `.github/workflows/build.yml` which currently runs on Windows, installs the Geode CLI & SDK, builds, and uploads the `.geode` artifact.

The badge above points to the build workflow for this repository.

## Install the .geode
- Open GD with Geode Loader
- Drag-and-drop the generated `.geode` file onto the game window, or place it in
  the Geode mods directory per your platform

## Usage
- Settings:
  - Enable No-Clip (bool): toggles skipping death checks
  - Toggle Key(s): choose from dropdown; supports multiple keys (comma-separated, e.g. "A,Space"). Invalid/empty keys fall back to RightShift.
- When enabled, player death is prevented by skipping `PlayLayer::destroyPlayer`

## Limitations
- This is a minimal no-death hack; some hazards may still cause issues (e.g.,
  forced death transitions, triggers). Full no-clip requires intercepting player
  collision logic to avoid death and avoid knockback/unstable states.
- Hook signatures may change across Geode/2.2 bindings. If compilation breaks,
  see `src/main.cpp` comments and adjust according to the bound headers.

## Project layout
- `mod.json` – metadata and settings
- `src/main.cpp` – hooks and setting/keybind logic
- `CMakeLists.txt` – CMake build (CLI recommended)

## License
MIT (replace with your preferred license)
