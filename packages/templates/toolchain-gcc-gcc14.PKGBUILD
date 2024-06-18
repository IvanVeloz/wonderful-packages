# SPDX-License-Identifier: CC0-1.0
#
# SPDX-FileContributor: Adrian "asie" Siekierka, 2024

if [ "x$GCC_IS_LIBSTDCXX" = "xyes" ]; then
	pkgname=(toolchain-gcc-$GCC_TARGET-libstdcxx-picolibc)
	depends=(toolchain-gcc-$GCC_TARGET-picolibc-generic)
	arch=(any)
else
	pkgname=(toolchain-gcc-$GCC_TARGET-gcc toolchain-gcc-$GCC_TARGET-gcc-libs)
	depends=(toolchain-gcc-$GCC_TARGET-binutils)
	arch=("x86_64" "aarch64" "arm64")
fi
pkgver=14.1.0
_gccver=14.1.0
_gmpver=6.3.0
_mpfrver=4.2.1
_mpcver=1.3.1
_islver=0.26
pkgdesc="The GNU Compiler Collection"
makedepends=(runtime-musl-dev)
groups=(toolchain-gcc-$GCC_TARGET)
url="https://gcc.gnu.org"
license=("GPL-3.0-or-later")
source=("http://ftp.gnu.org/gnu/gcc/gcc-$pkgver/gcc-$pkgver.tar.xz"
        "http://gmplib.org/download/gmp/gmp-$_gmpver.tar.xz"
        "http://www.mpfr.org/mpfr-$_mpfrver/mpfr-$_mpfrver.tar.xz"
        "http://ftp.gnu.org/gnu/mpc/mpc-$_mpcver.tar.gz"
	"https://libisl.sourceforge.io/isl-$_islver.tar.xz"
	"file:///Users/slacker/sources/wonderful-packages/patches/gcc14-poison-system-directories.patch"
	"file:///Users/slacker/sources/wonderful-packages/patches/gcc13-clang-MJ.patch"
	"file:///Users/slacker/sources/wonderful-packages/patches/gcc13-multilib-arm-elf"
)
sha256sums=(
	'e283c654987afe3de9d8080bc0bd79534b5ca0d681a73a11ff2b5d3767426840'
	'a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898'
	'277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2'
	'ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8'
	'a0b5cb06d24f9fa9e77b55fabbe9a3c94a336190345c2555f9915bb38e976504'
	'SKIP'
	'SKIP'
	'SKIP'
)

. "../../config/runtime-env-vars.sh"

prepare() {
	mkdir -p "gcc-build"
	cd "gcc-$_gccver"

	### Target patches

	# These patches are used by the toolchain and most likely necessary.
	# - HACK: hijack RTEMS's libstdc++ crossconfig for our own purposes (which has the dynamic feature checks we want)
	gsed -i "s/\*-rtems\*/*-unknown*/" libstdc++-v3/configure
	# - Add -MJ compile_commands.json fragment emitter, matching Clang.
	patch -p1 <../gcc13-clang-MJ.patch

	# These patches are used by the toolchain, but only serve an optimization purpose.
	# - Use custom multilib configuration on ARM.
	cp ../gcc13-multilib-arm-elf gcc/config/arm/t-arm-elf

	# These patches aren't strictly necessary, but they are nice to have.
	# - Poison system directories: emit warnings if they are mistakenly included.
	patch -p1 <../gcc14-poison-system-directories.patch

	ln -s ../"gmp-$_gmpver" gmp
	ln -s ../"mpfr-$_mpfrver" mpfr
	ln -s ../"mpc-$_mpcver" mpc
	ln -s ../"isl-$_islver" isl
}

build() {
	export PATH=/opt/wonderful/toolchain/gcc-$GCC_TARGET/bin:$PATH

	if [ "x$GCC_IS_LIBSTDCXX" = "xyes" ]; then
		build_libstdcxx_arg="--enable-libstdcxx"
		configure_cmd=../"gcc-$_gccver"/libstdc++-v3/configure

		wf_disable_host_build
	else
		build_libstdcxx_arg="--disable-libstdcxx"
		configure_cmd=../"gcc-$_gccver"/configure
	fi
	cd gcc-build

	# workaround for https://gcc.gnu.org/bugzilla/show_bug.cgi?id=108300
	if [ "$WF_HOST_OS" == "windows" ]; then
		CPPFLAGS='-DWIN32_LEAN_AND_MEAN'
	fi

	# TODO: It's strange that --with-gnu-as/--with-gnu-ld is required for cross-compilation.
	# I'd assume it would automatically check the target assembler/linker. I wonder what the issue is.
	$configure_cmd \
		--prefix="/opt/wonderful/toolchain/gcc-$GCC_TARGET" \
		--target=$GCC_TARGET \
		--with-pkgversion="Wonderful toolchain" \
		--with-bugurl="http://github.com/WonderfulToolchain/wonderful-packages/issues" \
		--with-stage1-ldflags="$WF_RUNTIME_LDFLAGS" \
		--without-headers \
		--enable-plugins \
		--enable-poison-system-directories \
		--disable-bootstrap \
		--disable-gcov \
		--disable-nls \
		--disable-shared \
		--disable-werror \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libstdcxx-pch \
		--disable-libstdcxx-threads \
		--disable-libstdcxx-verbose \
		--disable-libunwind-exceptions \
		--disable-threads \
		--with-gnu-as \
		--with-gnu-ld \
		--with-isl \
		$build_libstdcxx_arg \
		"${GCC_EXTRA_ARGS[@]}"

	make -j10
}

package_toolchain-gcc-template-gcc() {
	cd gcc-build
	make DESTDIR="$pkgdir" install-gcc install-libcc1
	cd "$pkgdir"
	wf_relocate_path_to_destdir

	rm toolchain/gcc-$GCC_TARGET/share/info/dir
	rm toolchain/gcc-$GCC_TARGET/lib/gcc/$GCC_TARGET/$pkgver/include-fixed/README

	# HACK: As we don't build with a C library present, limits.h
	# assumes no such library is present.

	cd "$srcdir"/gcc-"$_gccver"/gcc
	cat limitx.h glimits.h limity.h > "$pkgdir"/toolchain/gcc-$GCC_TARGET/lib/gcc/$GCC_TARGET/$pkgver/include/limits.h
}

package_toolchain-gcc-template-gcc-libs() {
	pkgdesc="GCC-provided libraries"
	depends=("toolchain-gcc-$GCC_TARGET-binutils" "toolchain-gcc-$GCC_TARGET-gcc")
	options=(!strip)

	cd gcc-build
	make DESTDIR="$pkgdir" install-target-libgcc
	cd "$pkgdir"
	wf_relocate_path_to_destdir

	# HACK: Avoid conflict with -gcc package.
	rm toolchain/gcc-$GCC_TARGET/lib/gcc/$GCC_TARGET/*/include/unwind.h
}

package_toolchain-gcc-template-libstdcxx-picolibc() {
	pkgdesc="GCC-provided libstdc++, compiled for use with picolibc"
	options=(!strip)

	cd gcc-build
	make DESTDIR="$pkgdir" install
	cd "$pkgdir"
	wf_relocate_path_to_destdir
	rm -r toolchain/gcc-$GCC_TARGET/lib/*.py || true
	rm -r toolchain/gcc-$GCC_TARGET/share || true

	mkdir toolchain/gcc-$GCC_TARGET/$GCC_TARGET
	mv toolchain/gcc-$GCC_TARGET/include toolchain/gcc-$GCC_TARGET/$GCC_TARGET/
	mv toolchain/gcc-$GCC_TARGET/lib toolchain/gcc-$GCC_TARGET/$GCC_TARGET/
}
