#!/usr/bin/env python3
"""Probe WCH xw compressed load/store encodings with the WCH binary tools."""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
from pathlib import Path


MNEMONICS = (
    "c.lbu",
    "c.lhu",
    "c.sb",
    "c.sh",
    "c.lbusp",
    "c.lhusp",
    "c.sbsp",
    "c.shsp",
)

REGS = [f"x{i}" for i in range(32)]
ABI_REGS = {"sp": "x2"}
IMM_VALUES = [-1, 0, 1, 2, 3, 4, 7, 8, 15, 16, 31, 32, 63, 64, 127, 128, 255, 256]


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True)


def write_case(path: Path, mnemonic: str, reg_a: str, reg_b: str | None, imm: int) -> None:
    if mnemonic.endswith("sp"):
        line = f"    {mnemonic} {reg_a}, {imm}(sp)\n"
    else:
        line = f"    {mnemonic} {reg_a}, {imm}({reg_b})\n"
    path.write_text("    .text\n" + line, encoding="ascii")


def parse_text_bytes(objdump_output: str) -> str | None:
    for line in objdump_output.splitlines():
        match = re.match(r"\s+0000\s+([0-9a-fA-F]{4})\b", line)
        if match:
            hexword = match.group(1).lower()
            return hexword[2:4] + hexword[0:2]
    return None


def assemble_one(
    as_exe: Path,
    objdump_exe: Path,
    tmp_dir: Path,
    mnemonic: str,
    reg_a: str,
    reg_b: str | None,
    imm: int,
    march: str,
    mabi: str,
) -> dict[str, object]:
    asm_path = tmp_dir / "case.s"
    obj_path = tmp_dir / "case.o"
    write_case(asm_path, mnemonic, reg_a, reg_b, imm)

    as_args = [str(as_exe), f"-march={march}", f"-mabi={mabi}", "-o", str(obj_path), str(asm_path)]
    as_run = run(as_args)
    row: dict[str, object] = {
        "mnemonic": mnemonic,
        "reg_a": reg_a,
        "reg_b": reg_b or "sp",
        "imm": imm,
        "accepted": as_run.returncode == 0,
        "encoding": "",
        "stderr": as_run.stderr.strip(),
    }
    if as_run.returncode != 0:
        return row

    dump_args = [str(objdump_exe), "-s", "-j", ".text", str(obj_path)]
    dump_run = run(dump_args)
    row["encoding"] = parse_text_bytes(dump_run.stdout) or ""
    return row


def build_probe_cases() -> list[tuple[str, str, str | None, int]]:
    cases: list[tuple[str, str, str | None, int]] = []

    base_mnemonics = ("c.lbu", "c.lhu", "c.sb", "c.sh")
    sp_mnemonics = ("c.lbusp", "c.lhusp", "c.sbsp", "c.shsp")

    for mnemonic in base_mnemonics:
        for reg_a in REGS:
            for reg_b in REGS:
                cases.append((mnemonic, reg_a, reg_b, 0))
        for imm in IMM_VALUES:
            cases.append((mnemonic, "x8", "x9", imm))
        for reg in ("sp",):
            cases.append((mnemonic, "x8", ABI_REGS[reg], 0))

    for mnemonic in sp_mnemonics:
        for reg_a in REGS:
            cases.append((mnemonic, reg_a, None, 0))
        for imm in IMM_VALUES:
            cases.append((mnemonic, "x8", None, imm))

    return cases


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--oracle-bin", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    parser.add_argument("--march", default="rv32ecxw")
    parser.add_argument("--mabi", default="ilp32e")
    args = parser.parse_args()

    as_exe = args.oracle_bin / "riscv-none-embed-as.exe"
    objdump_exe = args.oracle_bin / "riscv-none-embed-objdump.exe"
    args.out_dir.mkdir(parents=True, exist_ok=True)
    tmp_dir = args.out_dir / "tmp"
    tmp_dir.mkdir(parents=True, exist_ok=True)

    rows = [
        assemble_one(as_exe, objdump_exe, tmp_dir, mnemonic, reg_a, reg_b, imm, args.march, args.mabi)
        for mnemonic, reg_a, reg_b, imm in build_probe_cases()
    ]

    csv_path = args.out_dir / "xw-oracle.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=("mnemonic", "reg_a", "reg_b", "imm", "accepted", "encoding", "stderr"))
        writer.writeheader()
        writer.writerows(rows)

    summary: dict[str, dict[str, object]] = {}
    for mnemonic in MNEMONICS:
        accepted = [row for row in rows if row["mnemonic"] == mnemonic and row["accepted"]]
        summary[mnemonic] = {
            "accepted_count": len(accepted),
            "sample": accepted[:16],
        }
    json_path = args.out_dir / "xw-oracle-summary.json"
    json_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    print(f"wrote {csv_path}")
    print(f"wrote {json_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
