"""
Problem 5: Design a 2-coloring circuit for a bipartite graph

Graph: v1 — v2 — v3 — v4  (a simple path = bipartite)
Edges: (v1,v2), (v2,v3), (v3,v4)

For 2 colors, each vertex is either 0 or 1.
Adjacent vertices must have DIFFERENT colors.

Key formula — arithmetic XOR (equals 1 when inputs differ):
  vi + vj - 2 * vi * vj === 1
"""


def two_coloring_circuit(v1, v2, v3, v4):
    """
    Constraints:
      1. Binary: each vertex color is 0 or 1
      2. XOR:    adjacent vertices must differ

    The XOR formula:
      vi + vj - 2*vi*vj

    Truth table for XOR:
      0, 0 → 0 + 0 - 0 = 0  (same color — BAD)
      0, 1 → 0 + 1 - 0 = 1  (different — GOOD ✓)
      1, 0 → 1 + 0 - 0 = 1  (different — GOOD ✓)
      1, 1 → 1 + 1 - 2 = 0  (same color — BAD)
    """
    # Binary constraints
    for name, v in [("v1", v1), ("v2", v2), ("v3", v3), ("v4", v4)]:
        assert v * (v - 1) == 0, f"{name}={v} not binary"

    # Edge constraints: adjacent vertices must have different colors
    edge_v1_v2 = v1 + v2 - 2 * v1 * v2  # XOR
    edge_v2_v3 = v2 + v3 - 2 * v2 * v3
    edge_v3_v4 = v3 + v4 - 2 * v3 * v4

    return edge_v1_v2 == 1 and edge_v2_v3 == 1 and edge_v3_v4 == 1


# --- Test all 16 possible colorings ---
print("Problem 5: 2-coloring circuit for path graph v1—v2—v3—v4")
print("=" * 65)
print(f"{'v1':>4} {'v2':>4} {'v3':>4} {'v4':>4}  │  valid?")
print("─" * 65)

valid_count = 0
for v1 in [0, 1]:
    for v2 in [0, 1]:
        for v3 in [0, 1]:
            for v4 in [0, 1]:
                valid = two_coloring_circuit(v1, v2, v3, v4)
                if valid:
                    valid_count += 1
                    colors = []
                    for v in [v1, v2, v3, v4]:
                        colors.append("🔴" if v == 0 else "🔵")
                    coloring = " — ".join(colors)
                    print(
                        f"{v1:>4} {v2:>4} {v3:>4} {v4:>4}  │  ✓  {coloring}"
                    )

print(f"\n{valid_count} valid 2-colorings found out of 16 possible.")
print("(A path graph always has exactly 2 valid 2-colorings: alternating patterns)")
print()
print("The arithmetic circuit:")
print("  v1 * (v1 - 1) === 0                // binary")
print("  v2 * (v2 - 1) === 0                // binary")
print("  v3 * (v3 - 1) === 0                // binary")
print("  v4 * (v4 - 1) === 0                // binary")
print("  v1 + v2 - 2 * v1 * v2 === 1        // edge (v1, v2): must differ")
print("  v2 + v3 - 2 * v2 * v3 === 1        // edge (v2, v3): must differ")
print("  v3 + v4 - 2 * v3 * v4 === 1        // edge (v3, v4): must differ")
