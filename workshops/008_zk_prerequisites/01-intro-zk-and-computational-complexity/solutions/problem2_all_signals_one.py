"""
Problem 2: Arithmetic circuit satisfied when ALL signals are 1

Create an arithmetic circuit (using only +, -, ×, and === constraints)
that outputs 1 (satisfied) only when every input signal equals 1.
"""


def all_signals_are_one(*signals):
    """
    Circuit constraints:
      1. Each signal must be binary:  x * (x - 1) === 0
      2. All must be 1:              x1 * x2 * ... * xn === 1

    Why it works:
      - Binary constraint forces each signal to be 0 or 1
      - The product of all signals is 1 ONLY when every signal is 1
        (because 0 × anything = 0)
    """
    # Constraint 1: each signal is binary (0 or 1)
    for i, x in enumerate(signals):
        assert x * (x - 1) == 0, f"Signal x{i+1}={x} is not binary (0 or 1)"

    # Constraint 2: product of all signals === 1
    product = 1
    for x in signals:
        product *= x

    return product == 1


# --- Test all combinations for 3 signals ---
print("Problem 2: Circuit satisfied when ALL signals are 1")
print("=" * 55)
print(f"{'a':>3} {'b':>3} {'c':>3}  │  product  │  satisfied?")
print("─" * 55)

for a in [0, 1]:
    for b in [0, 1]:
        for c in [0, 1]:
            product = a * b * c
            satisfied = all_signals_are_one(a, b, c)
            marker = " ✓" if satisfied else ""
            print(f"{a:>3} {b:>3} {c:>3}  │  {product:>7}  │  {satisfied}{marker}")

print()
print("Only (1, 1, 1) satisfies the circuit — as expected.")
print()
print("The arithmetic circuit:")
print("  x1 * (x1 - 1) === 0   // binary constraint")
print("  x2 * (x2 - 1) === 0   // binary constraint")
print("  x3 * (x3 - 1) === 0   // binary constraint")
print("  x1 * x2 * x3  === 1   // all must be 1")
