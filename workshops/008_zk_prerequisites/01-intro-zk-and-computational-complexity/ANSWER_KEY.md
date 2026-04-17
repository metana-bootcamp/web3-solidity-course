# Workshop 1: Intro to ZK & Computational Complexity — Answer Key

## Problem 1: Classify P, NP, or PSPACE

| Problem | Class | Explanation |
|---------|-------|-------------|
| **Shortest path** | **P** | Dijkstra's runs in O(V²) — solvable AND verifiable in polynomial time |
| **Prime factorization** | **NP** | No known polynomial factoring algorithm, but given factors you multiply to verify instantly |
| **Best Go move** | **PSPACE** | Exponential game tree; even if someone gives you a "best move," verifying it's truly optimal requires exploring the tree |
| **Primality testing** | **P** | AKS algorithm (2002) runs in polynomial time. Also, Miller-Rabin is fast probabilistic test |

## Problem 2: Arithmetic circuit satisfied when ALL signals are 1

For signals `a`, `b`, `c` (binary-constrained):

```
// Constrain each signal to {0, 1}
a × (a - 1) === 0
b × (b - 1) === 0
c × (c - 1) === 0

// Require all to be 1
a × b × c === 1
```

**Why this works:** The binary constraints ensure each is 0 or 1. The product `a × b × c = 1` is only true when all three are 1 (since 0 × anything = 0).

**Alternative (simpler if already binary):**
```
a + b + c === 3
```

## Problem 3: Arithmetic circuit satisfied when at least one signal is 0

```
// Constrain to binary
a × (a - 1) === 0
b × (b - 1) === 0
c × (c - 1) === 0

// At least one is 0
a × b × c === 0
```

**Why this works:** If all are binary, the product is 0 if and only if at least one of them is 0.

## Problem 4: Convert (a ∨ b) ∧ ¬c to arithmetic

Standard Boolean-to-arithmetic conversions (for binary signals where 1 = true, 0 = false):

| Boolean | Arithmetic |
|---------|-----------|
| NOT x | 1 - x |
| a AND b | a × b |
| a OR b | 1 - (1-a)(1-b) = a + b - ab |

Applying:
```
// Binary constraints
a × (a - 1) === 0
b × (b - 1) === 0
c × (c - 1) === 0

// (a OR b) AND (NOT c) === 1
(a + b - a × b) × (1 - c) === 1
```

**Expanded:** `a - ac + b - bc - ab + abc === 1`

**Verify with truth table:**

| a | b | c | a∨b | ¬c | (a∨b)∧¬c | Arithmetic |
|---|---|---|-----|----|-----------|-----------| 
| 0 | 0 | 0 | 0 | 1 | 0 | (0+0-0)(1-0) = 0 ✓ |
| 0 | 1 | 0 | 1 | 1 | 1 | (0+1-0)(1-0) = 1 ✓ |
| 1 | 0 | 0 | 1 | 1 | 1 | (1+0-0)(1-0) = 1 ✓ |
| 1 | 1 | 0 | 1 | 1 | 1 | (1+1-1)(1-0) = 1 ✓ |
| 1 | 1 | 1 | 1 | 0 | 0 | (1+1-1)(1-1) = 0 ✓ |

## Problem 5: Design 2-coloring circuit for a bipartite graph

For a simple bipartite graph with edges (v₁,v₂), (v₂,v₃), (v₃,v₄):

```
// Each vertex gets color 0 or 1
v1 × (v1 - 1) === 0
v2 × (v2 - 1) === 0
v3 × (v3 - 1) === 0
v4 × (v4 - 1) === 0

// Adjacent vertices must have DIFFERENT colors
// For binary values: a ≠ b  ⟺  a + b - 2ab = 1  (XOR = 1)
v1 + v2 - 2 × v1 × v2 === 1   // edge (v1, v2)
v2 + v3 - 2 × v2 × v3 === 1   // edge (v2, v3)
v3 + v4 - 2 × v3 × v4 === 1   // edge (v3, v4)
```

**General formula:** For each edge (vᵢ, vⱼ):
```
vᵢ + vⱼ - 2 × vᵢ × vⱼ === 1
```
This is the arithmetic XOR — equals 1 only when exactly one is 0 and the other is 1.
