# WCH xw Compressed Extension

This note records the WCH `xw` compressed load/store behavior used by this reimplementation. The oracle was OpenWCH's `riscv-none-embed-as.exe` and `objdump.exe` from `openwch/risc-none-embed-gcc`; the local xPack `riscv-none-elf-gcc` under `E:\toolchains` was used only as a smoke/reference toolchain.

## Assembly gating

The WCH assembler accepts these instructions when `xw` is present in the RISC-V arch string, including:

- `-march=rv32ecxw -mabi=ilp32e`
- `-march=rv32imacxw -mabi=ilp32`
- `-march=rv32imafcxw -mabi=ilp32f`

The same `c.*` mnemonics are rejected without `xw`, for example `-march=rv32imac` rejects `c.lbu x8,0(x9)`. WCH `objdump` gates decoding with `-M xw`. This implementation follows that behavior and prints canonical `c.*` mnemonics when `-M xw` is enabled.

## Register and immediate constraints

| Instruction | Operands | Registers | Offset |
| --- | --- | --- | --- |
| `c.lbu` | `rd, imm(rs1)` | `rd=x8..x15`, `rs1=x8..x15` | `0..31`, byte aligned |
| `c.lhu` | `rd, imm(rs1)` | `rd=x8..x15`, `rs1=x8..x15` | `0..62`, even |
| `c.sb` | `rs2, imm(rs1)` | `rs2=x8..x15`, `rs1=x8..x15` | `0..31`, byte aligned |
| `c.sh` | `rs2, imm(rs1)` | `rs2=x8..x15`, `rs1=x8..x15` | `0..62`, even |
| `c.lbusp` | `rd, imm(sp)` | `rd=x8..x15` | `0..15`, byte aligned |
| `c.lhusp` | `rd, imm(sp)` | `rd=x8..x15` | `0..30`, even |
| `c.sbsp` | `rs2, imm(sp)` | `rs2=x8..x15` | `0..15`, byte aligned |
| `c.shsp` | `rs2, imm(sp)` | `rs2=x8..x15` | `0..30`, even |

Oracle probing also showed that normal `lbu/lhu/sb/sh` aliases compress to these encodings when operands match, including `sp` forms such as `lbu x8,0(sp)`. The bare names `lbusp/lhusp/sbsp/shsp` are not accepted.

## Encodings

All instructions are 16-bit compressed instructions. `rd'`, `rs1'`, and `rs2'` are the compressed register numbers encoded as register minus 8.

| Instruction | Match | Mask | Fields |
| --- | ---: | ---: | --- |
| `c.lbu` | `0x2000` | `0xe003` | `rd'=[4:2]`, `rs1'=[9:7]`, `imm[0]=[12]`, `imm[2:1]=[6:5]`, `imm[4:3]=[11:10]` |
| `c.lhu` | `0x2002` | `0xe003` | `rd'=[4:2]`, `rs1'=[9:7]`, `imm[2:1]=[6:5]`, `imm[4:3]=[11:10]`, `imm[5]=[12]` |
| `c.sb` | `0xa000` | `0xe003` | `rs2'=[4:2]`, `rs1'=[9:7]`, `imm[0]=[12]`, `imm[2:1]=[6:5]`, `imm[4:3]=[11:10]` |
| `c.sh` | `0xa002` | `0xe003` | `rs2'=[4:2]`, `rs1'=[9:7]`, `imm[2:1]=[6:5]`, `imm[4:3]=[11:10]`, `imm[5]=[12]` |
| `c.lbusp` | `0x8000` | `0xf863` | `rd'=[4:2]`, `imm[3:0]=[10:7]` |
| `c.lhusp` | `0x8020` | `0xf863` | `rd'=[4:2]`, `imm[3:1]=[10:8]`, `imm[4]=[7]` |
| `c.sbsp` | `0x8040` | `0xf863` | `rs2'=[4:2]`, `imm[3:0]=[10:7]` |
| `c.shsp` | `0x8060` | `0xf863` | `rs2'=[4:2]`, `imm[3:1]=[10:8]`, `imm[4]=[7]` |

## Oracle commands

The committed oracle harness is `xw-oracle/run_xw_oracle.py`. It records CSV/JSON output under the requested output directory.

```powershell
& .\work\openwch-risc-none-embed-gcc\bin\riscv-none-embed-as.exe -march=rv32ecxw -mabi=ilp32e xw.s -o xw.o
& .\work\openwch-risc-none-embed-gcc\bin\riscv-none-embed-objdump.exe -dr -M xw xw.o
```

The implementation was smoke-tested with the locally built `work\build-binutils-mingw64-nonls\gas\as-new.exe` and `work\build-binutils-mingw64-nonls\binutils\objdump.exe`.

The RISC-V GAS DejaGnu tests were also run after installing MSYS2 `dejagnu 1.6.3-2`, `expect 5.45.4-6`, and `tcl 8.6.12-3`:

```powershell
& E:\toolchains\msys64\usr\bin\bash.exe -lc 'export PATH=/mingw64/bin:/usr/bin:$PATH; cd /d/projects/lopple/xw-reimplementation/work/build-binutils-mingw64-nonls/gas && make check-DEJAGNU RUNTESTFLAGS="riscv.exp"'
```

Result: `58` expected passes, `10` untested existing attribute cases, and no failures. The new `xw-invalid`, `xw-no-disasm`, `xw-noarch`, `xw-rv32ec`, `xw-rv32imac`, and `xw-rv32imafc` tests all passed.

## Difference from later standard compressed load/store work

This is a WCH-specific `xw` extension. It uses encodings that overlap standard compressed floating-point load/store encodings when `xw` is not enabled. For that reason disassembly remains unchanged unless `-M xw` is specified.
