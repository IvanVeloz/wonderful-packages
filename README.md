# UNOFFICIAL macOS wonderful-packages

Repository containing **unofficial** build scripts and infrastructure based on Wonderful's Pacman-based packaging, specifically for macOS.

Note: Support is not provided by the Wonderful Toolchain upstream. I am happy to provide you volunteer support on this repo's issue tracker. If you want to report issues upstream, reproduce them using a Linux VM on your Mac with the official sources to rule out macOS specific issues.

## Supported targets

Listed from most to least supported.

| Target | Description | Container |
| - | - | - |
| macos/arm64  | macOS, arm64  | N/A | 
| macos/x86_64 | macOS, x86_64 | N/A | 


## Guide

As the packaging system is intended for internal use only, the list of tested setups is highly specific:

### Downloading dependencies

For macOS development, all you need is clang, brew, and pure grit (and a Mac). Start by installing Homebrew (also known as `brew`). Follow the [instructions](https://brew.sh) on the official website. This will also install clang, so you're all set.

Next, install `poetry` as follows:

    $ brew install poetry

### Downloading repositories

Before using `pkgtool` for the first time, one should initialize the Poetry-based virtual environment:

    $ poetry install

To start working with `pkgtool`, one must make mirrors of all the relevant repositories. This can be done by writing:

    $ ./pkgtool mirror -c [targets...]

If no `targets` are specified, all targets supported by your environment will be downloaded. The `-c` argument removes all outdated/unused packages.

### Building packages

Example call:

    $ ./pkgtool build wf-tools@x86_64,aarch64 target-wswan-examples 

### Building macOS bootstraps

The macOS bootstrap is effectively a self-contained repackagings of a pre-installed `wf-pacman` package, allowing easy end user installation.

    $ ./pkgtool build-bootstrap [targets...]

### Installation details

#### macOS

Installation instructions:

1. The repository must be installed to `/wf`. While `pkgtool` is directory-agnostic, the `PKGBUILD` scripts are not.
2. Install build dependencies, best obtained through [homebrew](https://brew.sh), a non-exhaustive list is: `cmake meson ninja coreutils`

Notes:

* `wf-pacman` is built as statically as possible with Apple's clang

## License

Unless otherwise specified, the build scripts (`config/`, `packages/`) are licensed under Creative Commons 0. I don't see why instructions on building otherwise libre toolchains should be restricted by copyright in any way.

The Python package management tool (`tool/`) is licensed under the MIT license.

If you'd like to use these scripts and/or tools to build your own repository or toolchain, I'd appreciate it if steps were made to ensure that such toolchains are not misrepresented as my own work.
