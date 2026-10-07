#!/bin/bash

# REPO MAINTAINERS: KEEP CHANGES TO THIS IN SYNC WITH /tools/LinuxOneShot/SetupProgram/PreCompile.sh
# No ~mso
set -e
set -x

#load dep exports
#need to switch to game dir for Dockerfile weirdness
original_dir=$PWD
cd "$1"
. dependencies.sh
cd "$original_dir"

#find out what we have (+e is important for this)
set +e
has_git="$(command -v git)"
has_cargo="$(command -v ~/.cargo/bin/cargo)"
has_sudo="$(command -v sudo)"
has_grep="$(command -v grep)"
set -e

# install cargo if needful
if ! [ -x "$has_cargo" ]; then
	echo "Installing rust..."
	curl https://sh.rustup.rs -sSf | sh -s -- -y
	. ~/.profile
fi

# apt packages, libssl needed by rust-g but not included in TGS barebones install
has_pkg_config="$(command -v pkg-config)"
if ! ( [ -x "$has_git" ] && [ -x "$has_grep" ] && [ -x "$has_pkg_config" ] && [ -f "/usr/lib/i386-linux-gnu/libssl.so" ] && [ -f "/usr/lib/i386-linux-gnu/libz.so" ] && ls -d /usr/lib/gcc/x86_64-linux-gnu/*/32 >/dev/null 2>&1 ); then
	# Package list as in tgstation's InstallDeps.sh. libssl1.1:i386 is not listed: it does not
	# exist on Ubuntu 22.04+, which BYOND 516 requires (glibc 2.34). The libssl-dev packages pull
	# in the libssl version rust-g links against.
	echo "Installing apt dependencies. If this fails because sudo needs a password, install them yourself:"
	echo "sudo apt-get install -y lib32z1 git pkg-config libssl-dev:i386 libssl-dev zlib1g-dev:i386 g++-multilib"
	if ! [ -x "$has_sudo" ]; then
		dpkg --add-architecture i386
		apt-get update
		apt-get install -y lib32z1 git pkg-config libssl-dev:i386 libssl-dev zlib1g-dev:i386 g++-multilib
		rm -rf /var/lib/apt/lists/*
	else
		sudo dpkg --add-architecture i386
		sudo apt-get update
		sudo apt-get install -y lib32z1 git pkg-config libssl-dev:i386 libssl-dev zlib1g-dev:i386 g++-multilib
		sudo rm -rf /var/lib/apt/lists/*
	fi
fi

# update rust-g
if [ ! -d "rust-g" ]; then
	echo "Cloning rust-g..."
	git clone https://github.com/tgstation/rust-g
	cd rust-g
	~/.cargo/bin/rustup target add i686-unknown-linux-gnu
else
	echo "Fetching rust-g..."
	cd rust-g
	git fetch
	~/.cargo/bin/rustup target add i686-unknown-linux-gnu
fi

echo "Deploying rust-g..."
git checkout "$RUST_G_VERSION"
env PKG_CONFIG_ALLOW_CROSS=1 ~/.cargo/bin/cargo build --release --target=i686-unknown-linux-gnu
mv target/i686-unknown-linux-gnu/release/librust_g.so "$1/librust_g.so"
cd ..


# compile tgui
echo "Compiling tgui..."
cd "$1"
chmod +x tools/bootstrap/node  # Workaround for https://github.com/tgstation/tgstation-server/issues/1167
env TG_BOOTSTRAP_CACHE="$original_dir" TG_BOOTSTRAP_NODE_LINUX=1 CBT_BUILD_MODE="TGS" tools/bootstrap/node tools/build/build.js
