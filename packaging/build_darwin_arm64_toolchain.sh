#!/usr/bin/env bash
set -euxo pipefail

archive_root="riscv-none-embed-gcc8-xw-apple-arm64"
archive_name="$archive_root.tgz"
work="$RUNNER_TEMP/xw-darwin-arm64-build"
repo_root="$GITHUB_WORKSPACE"
binutils_build="$work/build-binutils"
binutils_prefix="$work/xw-binutils"
gcc_src="$work/riscv-gcc-8.2.0-xpack"
gcc_build="$work/build-gcc"
prefix="$work/$archive_root"
tool_bin="$work/tool-bin"
xpack_extract="$work/xpack"

mkdir -p "$work" "$binutils_build" "$binutils_prefix" "$gcc_build" "$prefix" "$tool_bin" "$xpack_extract"

if ! command -v wget >/dev/null 2>&1; then
  brew install wget
fi

cd "$binutils_build"
"$repo_root/configure" \
  --target=riscv-none-elf \
  --program-prefix=riscv-none-embed- \
  --prefix="$binutils_prefix" \
  --disable-nls \
  --disable-werror \
  --with-system-zlib
make MAKEINFO=true -j"$(sysctl -n hw.ncpu)" all-binutils all-gas all-ld
make MAKEINFO=true install-binutils install-gas install-ld

for tool in ar as ld nm objcopy objdump ranlib readelf strip; do
  ln -sf "$binutils_prefix/bin/riscv-none-embed-$tool" "$tool_bin/riscv-none-elf-$tool"
  ln -sf "$binutils_prefix/bin/riscv-none-embed-$tool" "$tool_bin/riscv-none-embed-$tool"
done

git clone --depth 1 --branch sifive-gcc-8.2.0-xpack https://github.com/xpack-dev-tools/riscv-gcc.git "$gcc_src"
expected_gcc_commit="0c7a874f0"
actual_gcc_commit="$(git -C "$gcc_src" rev-parse --short HEAD)"
if [ "$actual_gcc_commit" != "$expected_gcc_commit" ]; then
  echo "unexpected riscv-gcc commit: $actual_gcc_commit, expected $expected_gcc_commit" >&2
  exit 1
fi
git -C "$gcc_src" apply "$repo_root/xw-gcc8-apple-arm64-host-multilib.patch"
cd "$gcc_src"
./contrib/download_prerequisites

cd "$gcc_build"
export PATH="$tool_bin:$binutils_prefix/bin:$PATH"
export CFLAGS="-O2 -Wno-error=implicit-function-declaration -Wno-error=incompatible-function-pointer-types -Wno-error=int-conversion"
export CXXFLAGS="$CFLAGS"
"$gcc_src/configure" \
  --target=riscv-none-elf \
  --program-prefix=riscv-none-embed- \
  --prefix="$prefix" \
  --with-as="$binutils_prefix/bin/riscv-none-embed-as" \
  --with-ld="$binutils_prefix/bin/riscv-none-embed-ld" \
  --with-newlib \
  --without-headers \
  --with-system-zlib \
  --enable-languages=c,lto \
  --enable-lto \
  --enable-multilib \
  --disable-shared \
  --disable-threads \
  --disable-nls \
  --disable-werror \
  --disable-libssp \
  --disable-libstdcxx \
  --disable-libquadmath \
  --disable-libgomp \
  --disable-libatomic
make MAKEINFO=true -j"$(sysctl -n hw.ncpu)" all-gcc
make MAKEINFO=true -j"$(sysctl -n hw.ncpu)" all-target-libgcc
make MAKEINFO=true install-gcc install-target-libgcc
cc "$repo_root/packaging/xw_gcc_wrapper.c" -O2 -Wall -Wextra -o "$work/xw-gcc-wrapper"

curl -L "$XPACK_RELEASE_BASE/xpack-riscv-none-embed-gcc-$XPACK_VERSION-darwin-x64.tgz" -o "$work/xpack-darwin-x64.tgz"
tar -xzf "$work/xpack-darwin-x64.tgz" -C "$xpack_extract"
xpack_gcc="$(find "$xpack_extract" -type f -path '*/bin/riscv-none-embed-gcc' -print -quit)"
if [ -z "$xpack_gcc" ]; then
  echo "riscv-none-embed-gcc not found in xPack archive" >&2
  exit 1
fi
xpack_prefix="$(cd "$(dirname "$xpack_gcc")/.." && pwd)"

mkdir -p "$prefix/bin" "$prefix/riscv-none-elf/bin" "$prefix/riscv-none-elf/include" "$prefix/riscv-none-elf/lib"
cp -p "$binutils_prefix/bin"/riscv-none-embed-* "$prefix/bin"/
cp -p "$binutils_prefix/riscv-none-elf/bin"/* "$prefix/riscv-none-elf/bin"/
cp -a "$xpack_prefix/riscv-none-embed/include/." "$prefix/riscv-none-elf/include/"
cp -a "$xpack_prefix/riscv-none-embed/lib/." "$prefix/riscv-none-elf/lib/"
bash "$repo_root/packaging/install_xw_gcc_wrappers.sh" "$prefix" "$work/xw-gcc-wrapper"

file "$prefix/bin/riscv-none-embed-gcc" \
  "$prefix/bin/riscv-none-embed-as" \
  "$prefix/bin/riscv-none-embed-ld" \
  "$prefix/bin/riscv-none-embed-objcopy" \
  "$prefix/libexec/gcc/riscv-none-elf/8.2.0/liblto_plugin.so"

for arch in rv32e rv32ec rv32em rv32emc rv32eac rv32emac rv32imac rv32imc rv64imac; do
  abi=lp64
  case "$arch" in
    rv32e*) abi=ilp32e ;;
    rv32*) abi=ilp32 ;;
  esac
  printf '%-8s ' "$arch"
  "$prefix/bin/riscv-none-embed-gcc" -march="$arch" -mabi="$abi" -print-multi-directory
done

cat > "$work/xw-smoke.s" <<'EOS'
.option rvc
.text
c.lbu a0, 0(a1)
c.lhu a2, 2(a3)
c.sb a4, 1(a5)
c.sh a0, 2(a1)
EOS
"$prefix/bin/riscv-none-embed-as" -march=rv32ecxw "$work/xw-smoke.s" -o "$work/xw-smoke.o"
"$prefix/bin/riscv-none-embed-objdump" -d -M xw "$work/xw-smoke.o"
echo 'int f(void) { return 0; }' > "$work/probe.c"
"$prefix/bin/riscv-none-embed-gcc" -march=rv32ecxw -mabi=ilp32e -c "$work/probe.c" -o "$work/rv32ecxw.o"
"$prefix/bin/riscv-none-embed-gcc" -march=rv32imacxw -mabi=ilp32 -c "$work/probe.c" -o "$work/rv32imacxw.o"
"$prefix/bin/riscv-none-embed-gcc" -march=rv32ecxw -mabi=ilp32e -c "$work/xw-smoke.s" -o "$work/xw-gcc-smoke.o"

unset CFLAGS CXXFLAGS
git clone --depth 1 --branch b003-gcc8-asm-stability-test.1 --recurse-submodules https://github.com/lopple/rv003usb.git "$work/rv003usb"
curl -L https://github.com/lopple/rv003usb/releases/download/b003-gcc8-asm-stability-test.1/bootloader.bin -o "$work/release-bootloader.bin"
cd "$work/rv003usb/bootloader"
make build PREFIX="$prefix/bin/riscv-none-embed"
built_sha="$(shasum -a 256 bootloader.bin | awk '{print $1}')"
asset_sha="$(shasum -a 256 "$work/release-bootloader.bin" | awk '{print $1}')"
echo "built_sha=$built_sha"
echo "asset_sha=$asset_sha"
cmp -s bootloader.bin "$work/release-bootloader.bin"
echo "bootloader.bin byte-identical: yes"

cd "$work"
tar -czf "$repo_root/$archive_name" "$archive_root"
sha="$(shasum -a 256 "$repo_root/$archive_name" | awk '{print $1}')"
size="$(wc -c < "$repo_root/$archive_name" | tr -d ' ')"
python3 - <<EOF
import json
data = {
    "host": "arm64-apple-darwin",
    "archiveFileName": "$archive_name",
    "checksum": "SHA-256:$sha",
    "size": "$size",
}
with open("$repo_root/metadata-darwin-arm64.json", "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\\n")
EOF