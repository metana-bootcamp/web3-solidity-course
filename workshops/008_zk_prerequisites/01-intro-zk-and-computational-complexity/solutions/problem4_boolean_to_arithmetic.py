"""
Problem 4: Convert Boolean formula to arithmetic
  out = (a OR b) AND (NOT c)

Conversion table:
  NOT x   →  1 - x
  a AND b →  a * b
  a OR b  →  a + b - a*b   (equivalently: 1 - (1-a)(1-b))
"""


def boolean_version(a, b, c):
    """Original Boolean formula using Python keywords."""
    return (a or b) and (not c)


def arithmetic_version(a, b, c):
    """
    Step-by-step conversion:

    1. NOT c         →  (1 - c)
    2. a OR b        →  a + b - a*b
    3. (a OR b) AND (NOT c)  →  (a + b - a*b) * (1 - c)

    Expanded:
      = a(1-c) + b(1-c) - ab(1-c)
      = a - ac + b - bc - ab + abc
    """
    # Binary constraints
    assert a * (a - 1) == 0, f"a={a} not binary"
    assert b * (b - 1) == 0, f"b={b} not binary"
    assert c * (c - 1) == 0, f"c={c} not binary"

    # The arithmetic formula
    return (a + b - a * b) * (1 - c)


# --- Verify: both versions produce identical results for all inputs ---
print("Problem 4: Convert (a OR b) AND (NOT c) to arithmetic")
print("=" * 65)
print(f"{'a':>3} {'b':>3} {'c':>3}  │  Boolean  │  Arithmetic  │  Match?")
print("─" * 65)

all_match = True
for a in [0, 1]:
    for b in [0, 1]:
        for c in [0, 1]:
            bool_result = 1 if boolean_version(a, b, c) else 0
            arith_result = arithmetic_version(a, b, c)
            match = bool_result == arith_result
            if not match:
                all_match = False
            print(
                f"{a:>3} {b:>3} {c:>3}  │  {bool_result:>7}  │  {arith_result:>10}  │  {'✓' if match else '✗'}"
            )

print()
if all_match:
    print("All 8 combinations match — conversion is correct!")
else:
    print("MISMATCH FOUND — check the formula!")

print()
print("The arithmetic circuit:")
print("  a * (a - 1) === 0              // binary constraint")
print("  b * (b - 1) === 0              // binary constraint")
print("  c * (c - 1) === 0              // binary constraint")
print("  (a + b - a*b) * (1 - c) === 1  // formula: (a OR b) AND (NOT c)")
