# ScummVM libretro core

Libretro core built directly from untouched mainline ScummVM source.

ScummVM main repo is included as a submodule. To sync the libretro core it should be sufficient to update the submodule and build.

Submodule updates are generally committed following ScummVM official releases (though it can be updated to any commit upstream, considering that adjustment to core makefiles and sources in `src` may be required to build). First three fields of core tags are relevant to upstream ScummVM version, last is libretro core revision (e.g. v2.6.1.1 is ScummVM 2.6.1, core revision 1).

Datafiles and themes bundle (`scummvm.zip`) and `core.info` files are built automatically based on current submodule source.

## Build
To build the core with the default configuration, type in a shell the following:
```
git clone --recursive https://github.com/libretro/scummvm
cd scummvm
make
```
Use `make all` to build the core along with datafiles/themes (`scummvm.zip`) and core info file (which can be built separately with `make datafiles`/`make infofile`).

"Work in progress" engines are not built by default, to include them pass `NO_WIP=0` to make.

To crossbuild for specific platforms, pass the relevant `platform` variable to make (refer to Makefile for supported ones).

### Build for Android
To build for Android:
* install android-sdk
* install android-ndk (e.g. through sdkmanager included in android-sdk/cmdline-tools)
* make sure all needed sdk/ndk paths are included in PATH
* type in a shell the following:
```
git clone --recursive https://github.com/libretro/scummvm
cd scummvm/jni
ndk-build
```
Core will be built for all available android targets by default

### Data files and themes
[Data files](https://wiki.scummvm.org/index.php/Datafiles) required for certain games and core functions (e.g. virtual keyboard) and default [ScummVM GUI themes](https://wiki.scummvm.org/index.php/GUI_Themes) are bundled during the build process in `scummvm.zip` file. Libretro core info file is created during build as well.
Extract `scummvm.zip` and select relevant paths in ScummVM GUI (or modify `scummvm.ini` accordingly) to load properly needed data files/themes in the core.

Note that both datafiles and themes included in `scummvm.zip` need to be consistent with ScummVM version (e.g. v2.6.1.x), hence need to be generally rebuilt and replaced for each new version.

## Core options and configuration
All options and configuration of the legacy libretro core are applicable to this one as well, refer to relevant link in Resources.

Some additional options have been added to this core:
* On-screen virtual keyboard (retropad "select" button by default to activate/deactivate)
* Set D-pad cursor acceleration time

## Resources
Official ScummVM repository readme is [here](https://github.com/scummvm/scummvm#readme).

[Legacy ScummVM libretro core](https://github.com/libretro-mirrors/scummvm) documentation is [here](https://docs.libretro.com/library/scummvm).
