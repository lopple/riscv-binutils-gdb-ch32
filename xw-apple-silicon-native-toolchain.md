# Apple Silicon native WCH xw GCC 8 toolchain verification

Date: 2026-07-02
Host: Apple Silicon macOS on tt@mm1
Prefix: `/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-apple-arm64-full-match`
Archive: `riscv-none-embed-gcc8-xw-apple-arm64-full-20260702.tgz`
SHA256: `23ab7581ba572d84b44d6bdd2ff7943c6a27b8eb3d9bd54bc337e20fe483ff63`

## Contents

- GCC 8.2.0 host tools built as Mach-O arm64.
- WCH xw binutils host tools built as Mach-O arm64.
- LTO plugin built as Mach-O arm64.
- RISC-V target newlib headers/libraries staged from xPack GCC 8.2.0-3.1 sysroot.
- RISC-V libgcc rebuilt with xPack-style embedded multilibs, including rv32e/ilp32e.

## Host binary check

```text
/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-apple-arm64-full-match/bin/riscv-none-embed-gcc:                          Mach-O 64-bit executable arm64
/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-apple-arm64-full-match/bin/riscv-none-embed-as:                           Mach-O 64-bit executable arm64
/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-apple-arm64-full-match/bin/riscv-none-embed-ld:                           Mach-O 64-bit executable arm64
/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-apple-arm64-full-match/bin/riscv-none-embed-objcopy:                      Mach-O 64-bit executable arm64
/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-apple-arm64-full-match/libexec/gcc/riscv-none-elf/8.2.0/liblto_plugin.so: Mach-O 64-bit bundle arm64
```

## Multilib selection spot checks

```text
rv32e    rv32e/ilp32e
rv32ec   rv32e/ilp32e
rv32em   rv32em/ilp32e
rv32emc  rv32em/ilp32e
rv32eac  rv32eac/ilp32e
rv32emac rv32emac/ilp32e
rv32imac rv32imac/ilp32
rv32imc  rv32im/ilp32
rv64imac rv64imac/lp64
```

Selected libgcc for `-march=rv32ec -mabi=ilp32e`:

```text
/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-apple-arm64-full-match/lib/gcc/riscv-none-elf/8.2.0/rv32e/ilp32e/libgcc.a
```

## rv003usb b003 verification

Built `rv003usb` tag `b003-gcc8-asm-stability-test.1` from a cleaned `bootloader` directory using:

```sh
make build PREFIX="/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-apple-arm64-full-match/bin/riscv-none-embed"
```

Result:

```text
built_sha=78472f11ca4c147a8b00a9b73e2fac5176c944d1edb05d94977bb92a0d3a4c7f
asset_sha=78472f11ca4c147a8b00a9b73e2fac5176c944d1edb05d94977bb92a0d3a4c7f
bootloader.bin byte-identical: yes
```
