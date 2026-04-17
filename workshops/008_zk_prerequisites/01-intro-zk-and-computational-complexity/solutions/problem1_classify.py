"""
Problem 1: Classify as P, NP, or PSPACE

- Shortest path in a graph
- Prime factorization
- Best Go move
- Primality testing

These aren't code problems — they're classification questions.
Below we verify each classification with reasoning.
"""

classifications = {
    "Shortest path in a graph": {
        "class": "P",
        "reason": (
            "Dijkstra's algorithm solves it in O(V^2) time. "
            "Given a proposed path, checking it is even faster — "
            "just follow the edges and add up the weights."
        ),
    },
    "Prime factorization": {
        "class": "NP",
        "reason": (
            "No known polynomial-time algorithm to FIND the prime factors of a large number. "
            "But given candidate factors, you just multiply them together and check: "
            "does the product equal the original number? That's O(n) multiplication — fast."
        ),
    },
    "Best Go move": {
        "class": "PSPACE",
        "reason": (
            "The game tree for Go is astronomically large. "
            "Even if someone TELLS you a move, verifying it's truly the BEST move "
            "requires exploring every possible opponent response, every counter-move, etc. "
            "There's no shortcut — no 'receipt' that makes checking fast."
        ),
    },
    "Primality testing": {
        "class": "P",
        "reason": (
            "The AKS algorithm (2002) proves primality in polynomial time. "
            "In practice, Miller-Rabin is used — a fast probabilistic test. "
            "Both solving AND checking are efficient."
        ),
    },
}

print("=" * 60)
print("Problem 1: Classify P, NP, or PSPACE")
print("=" * 60)
for problem, info in classifications.items():
    print(f"\n  {problem}")
    print(f"  → {info['class']}")
    print(f"    {info['reason']}")
print()
