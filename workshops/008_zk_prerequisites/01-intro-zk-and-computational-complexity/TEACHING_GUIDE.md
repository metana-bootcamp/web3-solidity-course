# Workshop 1: Intro to ZK & Computational Complexity — Teaching Guide

## Opening Hook (5 min)
**"The Password Paradox"**

> *"Every time you log in to a website, you prove you know the password... by revealing the password. What if you could prove you know it without ever sending it?"*

That's Zero Knowledge Proofs in one sentence.

## Key Analogies

| Concept | Analogy |
|---------|---------|
| **ZK Proof** | "Where's Waldo?" — point through a tiny hole in a card. Verifier sees Waldo, never learns his location on the page. |
| **P vs NP** | **P** = jigsaw puzzle with the picture on the box. **NP** = jigsaw puzzle with no picture — brutal to solve, trivial to verify when complete. |
| **PSPACE** | Playing chess — even if told "move Queen to E5," you can't verify it's *optimal* without replaying the entire game tree. |
| **Witness** | A solved Sudoku grid. The grid *is* the proof the puzzle is solvable. ZKPs let you prove "I have a solved grid" without showing numbers. |
| **Boolean Circuit** | Writing a program using only `if/else` and `true/false` — powerful but verbose. |
| **Arithmetic Circuit** | Writing a program using only `+`, `×`, and `===`. Surprisingly equivalent to Boolean. |

## Live Demo: 3-Coloring (10 min)
Draw a simple graph (triangle + extra node) on the board.
1. Ask: *"Can you color this with 3 colors so no neighbors match?"*
2. Students solve it (1-2 min)
3. Ask: *"How would you PROVE you solved it without showing your coloring?"*
4. Walk through: commit colors in sealed envelopes, verifier picks one edge, reveal only those two nodes. Repeat.

## Mid-Session Checkpoint
After the P/NP/PSPACE section, do a quick classification game:

| Problem | Students vote | Answer |
|---------|--------------|--------|
| Binary search | P/NP/PSPACE? | **P** |
| Sudoku (9×9) | P/NP/PSPACE? | **NP** |
| Best Go move | P/NP/PSPACE? | **PSPACE** |
| "Is this number prime?" | P/NP/PSPACE? | **P** (AKS test) |

## Discussion Prompts
- *"Is sorting P or NP?"* (P — merge sort is O(n log n), verification also easy)
- *"Is breaking AES encryption P, NP, or PSPACE?"* (Believed NP — given the key, verification is instant)
- *"Why can't we make ZK proofs for chess?"* (PSPACE — no efficient witness/verification)

## Common Student Mistakes
- Confusing "hard to solve" with "hard to verify" — NP means **easy to verify**
- Thinking ZKPs help you *find* solutions — they only prove you *have* one
- Forgetting P ⊂ NP (everything in P is also in NP)

## Transition to Next Workshop
> *"We've seen arithmetic circuits as the foundation. But what number system do they operate in? Hint: NOT regular integers. Next time — finite fields, where division never produces fractions."*
