# ALU Design Project

##  Overview

This project presents a fully parameterized **Arithmetic Logic Unit (ALU)** designed and verified by **Kanthimathi C**. The ALU performs a variety of arithmetic, logical, shifting, and rotational operations on binary inputs, with comprehensive support for operand validation, flags, and error detection.

The design supports both **arithmetic and logical modes**, with fine-grained control signals and parameterizable data width.

---

##  Key Features

### Arithmetic Operations (when `MODE = 1`)
- ADD, SUB
- ADD with carry-in, SUB with carry-in
- INC / DEC for A and B
- CMP (Comparison)
- Compound operations like:
  - INC A & B → then multiply
  - Shift A → then multiply with B
  - Signed/unsigned ADD/SUB with overflow, carry, and flags

###  Logical Operations (when `MODE = 0`)
- AND, NAND
- OR, NOR
- XOR, XNOR
- NOT (A/B)
- Shift left/right A and B
- Rotate left/right A based on value in B (ROL_A_B / ROR_A_B)

---

##  Pin-Level Interface

###  Inputs

| Pin Name   | Width  | Description |
|------------|--------|-------------|
| `OPA`, `OPB` | Param | Operand inputs |
| `CIN`      | 1      | Carry-in (active high) |
| `CLK`      | 1      | Clock (edge-sensitive) |
| `RST`      | 1      | Reset (active high, asynchronous) |
| `CE`       | 1      | Clock enable (active high) |
| `MODE`     | 1      | Operation type: `1` = Arithmetic, `0` = Logical |
| `INP_VALID`| 2      | Valid input flags: 00 = none, 11 = both valid |
| `CMD`      | 4      | Command selector (arithmetic/logical/rotate etc.) |

###  Outputs

| Pin Name | Width | Description |
|----------|-------|-------------|
| `RES`    | Param + 1 | Operation result |
| `OFLOW`  | 1     | Overflow flag |
| `COUT`   | 1     | Carry-out flag |
| `G`, `L`, `E` | 1 | Comparison flags: Greater, Less, Equal |
| `ERR`    | 1     | Error flag (for invalid rotate conditions) |

---

##  Usage Guidelines

- Both operands must be valid (`INP_VALID = 11`) for dual-operand commands (e.g., ADD, SUB).
- Only one operand should be valid for single-operand commands (e.g., INC_A, NOT_A).
- For `ROL_A_B` / `ROR_A_B`, bits `[7:4]` of `OPB` must be `0000` or an error (`ERR`) is raised.
- All outputs are registered and computed after 3 clock cycles post input application.

---

##  Files Included
- Design code 
- test vector generator with reference model to update expected result in the stimulus.
- tb included with driver , monitor, scoreboard and checker.
- stimulus file generated
- results file
- report document
- test plan
- coverage report with 93% coverage

