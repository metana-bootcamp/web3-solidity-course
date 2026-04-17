"""
Problem 3: Arithmetic circuit satisfied when at least one signal is 0

Create an arithmetic circuit that outputs 1 (satisfied) only when
at least one input signal equals 0.
"""


def at_least_one_zero(*signals):
    """
    Circuit constraints:
      1. Each signal must be binary:  x * (x - 1) === 0
      2. At least one is 0:          x1 * x2 * ... * xn === 0

    Why it works:
      - Binary constraint forces each signal to be 0 or 1
      - The product is 0 if ANY signal is 0
        (because 0 × anything = 0)
      - The product is 1 only when ALL signals are 1
        → so product === 0 means "not all are 1" = "at least one is 0"
    """
    # Constraint 1: each signal is binary
    for i, x in enumerate(signals):
        assert x * (x - 1) == 0, f"Signal x{i+1}={x} is not binary (0 or 1)"

    # Constraint 2: product === 0
    product = 1
    for x in signals:
        product *= x

    return product == 0


# --- Test all combinations for 3 signals ---
print("Problem 3: Circuit satisfied when at least one signal is 0")
print("=" * 55)
print(f"{'a':>3} {'b':>3} {'c':>3}  │  product  │  satisfied?")
print("─" * 55)

for a in [0, 1]:
    for b in [0, 1]:
        for c in [0, 1]:
            product = a * b * c
            satisfied = at_least_one_zero(a, b, c)
            marker = " ✓" if satisfied else ""
            print(f"{a:>3} {b:>3} {c:>3}  │  {product:>7}  │  {satisfied}{marker}")

print()
print("Every combination EXCEPT (1,1,1) satisfies the circuit.")
print()
print("The arithmetic circuit:")
print("  x1 * (x1 - 1) === 0   // binary constraint")
print("  x2 * (x2 - 1) === 0   // binary constraint")
print("  x3 * (x3 - 1) === 0   // binary constraint")
print("  x1 * x2 * x3  === 0   // at least one must be 0")
