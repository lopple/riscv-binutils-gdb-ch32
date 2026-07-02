# Darwin x86_64 WCH xw GCC 8 toolchain verification

Date: 2026-07-02
Host used for test: Apple Silicon macOS on tt@mm1, under Rosetta x86_64 runtime
Prefix: `/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-darwin-x64`
Archive: `riscv-none-embed-gcc8-xw-darwin-x64-20260702.tgz`
SHA256: `6ffea5d0a77f1332c47ddf4f27f9b469e2be7770b6e16f6e06de87bd0947334c`

## Contents

- xPack GCC 8.2.0-3.1 darwin-x64 GCC/sysroot/multilib base.
- WCH xw binutils rebuilt as Mach-O x86_64 and staged into both `bin/` and `riscv-none-embed/bin/`.
- LTO plugin is the xPack darwin-x64 Mach-O x86_64 plugin.
- Multilib selection matches xPack, including `rv32ec -> rv32e/ilp32e`.

## Host binary check

```text
/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-darwin-x64/bin/riscv-none-embed-gcc:                            Mach-O 64-bit executable x86_64
/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-darwin-x64/bin/riscv-none-embed-as:                             Mach-O 64-bit executable x86_64
/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-darwin-x64/bin/riscv-none-embed-ld:                             Mach-O 64-bit executable x86_64
/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-darwin-x64/bin/riscv-none-embed-objcopy:                        Mach-O 64-bit executable x86_64
/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-darwin-x64/libexec/gcc/riscv-none-embed/8.2.0/liblto_plugin.so: Mach-O 64-bit bundle x86_64
```

## xw smoke

Assembled with `-march=rv32ecxw` and disassembled with `-M xw`:

```text
0: 2188 c.lbu a0,0(a1)
2: 22b2 c.lhu a2,2(a3)
4: b398 c.sb a4,1(a5)
6: a1aa c.sh a0,2(a1)
```

## rv003usb b003 verification

Runtime architecture during test: `x86_64`.

Built `rv003usb` tag `b003-gcc8-asm-stability-test.1` from a cleaned `bootloader` directory using:

```sh
make build PREFIX="/Users/tt/codex/xw-reimplementation/work/riscv-none-embed-gcc8-xw-darwin-x64/bin/riscv-none-embed"
```

Result:

```text
built_sha=78472f11ca4c147a8b00a9b73e2fac5176c944d1edb05d94977bb92a0d3a4c7f
asset_sha=78472f11ca4c147a8b00a9b73e2fac5176c944d1edb05d94977bb92a0d3a4c7f
bootloader.bin byte-identical: yes
```
