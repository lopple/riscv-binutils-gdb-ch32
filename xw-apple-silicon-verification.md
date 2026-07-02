# WCH xw Apple Silicon verification

Date: 2026-07-02

Remote host:

- SSH: `ssh -i "$env:USERPROFILE\.ssh\mac_codex" tt@mm1`
- OS: macOS 26.4.1, Darwin 25.4.0
- Host architecture: `arm64`

Built native arm64 binutils from commit `4de58899b0`:

```text
configure --target=riscv-none-elf \
  --program-prefix=riscv-none-embed- \
  --prefix="$HOME/codex/xw-reimplementation/work/xw-binutils-apple-arm64" \
  --disable-nls --disable-werror --with-system-zlib

make MAKEINFO=true all-binutils all-gas all-ld
make MAKEINFO=true install-binutils install-gas install-ld
```

The installed tools are native Apple Silicon executables:

```text
riscv-none-embed-as:      Mach-O 64-bit executable arm64
riscv-none-embed-objdump: Mach-O 64-bit executable arm64
riscv-none-embed-ld:      Mach-O 64-bit executable arm64
```

Minimal xw probe:

```text
$ riscv-none-embed-as -march=rv32ecxw -o xw-probe.o xw-probe.s
$ riscv-none-embed-objdump -d -M xw xw-probe.o
0: 2080 c.lbu s0,0(s1)
2: 21aa c.lhu a0,2(a1)
4: b2b0 c.sb a2,3(a3)
6: a3fa c.sh a4,6(a5)
```

rv003usb comparison:

- Repository: `https://github.com/lopple/rv003usb.git`
- Tag: `b003-gcc8-asm-stability-test.1`
- Commit: `3db5fea8ff76622846c5bf2c4f74d67cdea6c1f9`
- `ch32fun` submodule: `1e4887e11d4bfa739ed5604524b69f5be9f9275b`

GCC 8 note:

- xPack/WCH-compatible GCC 8.2.0 provides `darwin-x64`, not `darwin-arm64`.
- The rv003usb LTO link requires xPack x86_64 `ld`, because GCC's `liblto_plugin.so` is x86_64.
- The verified hybrid used x86_64 GCC/LD via Rosetta and native arm64 xw assembler/object tools.

Build command:

```text
make build PREFIX="$HOME/codex/xw-reimplementation/work/hybrid-gcc8-xw-apple-arm64-binutils/bin/riscv-none-embed"
```

Result:

```text
built_sha=78472f11ca4c147a8b00a9b73e2fac5176c944d1edb05d94977bb92a0d3a4c7f
asset_sha=78472f11ca4c147a8b00a9b73e2fac5176c944d1edb05d94977bb92a0d3a4c7f
bootloader.bin byte-identical: yes
```

Local binary artifact:

```text
work/dist/xw-binutils-apple-arm64-4de58899b0-darwin-arm64.tgz
SHA256: 6f3bdd7050c5aca78674f0fb73d79041a6284d7d3f3daa2f09b797c0dc20c3b3
```
