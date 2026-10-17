# Graph Report - javelina  (2026-10-17)

## Corpus Check
- 92 files · ~119,616 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 14 file(s) not represented in the graph (top: .xml 5, (none) 3, .log 2)

## Summary
- 372 nodes · 413 edges · 59 communities (19 shown, 40 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- re
- ks_derive.js
- matrix2.js
- struct
- aes_derived.js
- key32_ivs.js
- ofb_d_test.js
- aes_test.js
- blob_aes.js
- brute_phase.js
- combo_test.js
- ks2.js
- cfb_test.js
- HANDOFF — graphify graph for javelina
- values_dump.js
- Javelin3 DRM sample corpus
- xor_test.js
- make_te0
- sys
- auth_send2.ps1
- ref_fs

## God Nodes (most connected - your core abstractions)
1. `main()` - 6 edges
2. `urls()` - 5 edges
3. `HANDOFF — graphify graph for javelina` - 5 edges
4. `Javelin3 DRM sample corpus` - 5 edges
5. `consider()` - 4 edges
6. `find_call_sites()` - 3 edges
7. `dump_pe()` - 3 edges
8. `parse_exports()` - 3 edges
9. `get()` - 3 edges
10. `get()` - 3 edges

## Surprising Connections (you probably didn't know these)
- `dump_pe()` --calls--> `re`  [EXTRACTED]
  cnt_dump.py →   _Bridges community 3 → community 0_

## Import Cycles
- None detected.

## Communities (59 total, 40 thin omitted)

### Community 0 - "re"
Cohesion: 0.13
Nodes (12): get(), have(), urls(), collect(), consider(), get(), main(), save() (+4 more)

### Community 1 - "ks_derive.js"
Cohesion: 0.22
Nodes (8): bufs, cfk2, ct, data, diff, fs, known, ks

### Community 2 - "matrix2.js"
Cohesion: 0.11
Nodes (15): bufs, crypto, ct, data, fs, modes, TARGET, CFkey2 (+7 more)

### Community 3 - "struct"
Cohesion: 0.11
Nodes (9): xrefs(), find_call_sites(), dump_pe(), parse_exports(), i32(), rel(), pe_info(), find_dword() (+1 more)

### Community 4 - "aes_derived.js"
Cohesion: 0.10
Nodes (18): CFkey2, CFkey2_32, crypto, ct, data, fs, iv0_32, iv1_32 (+10 more)

### Community 5 - "key32_ivs.js"
Cohesion: 0.12
Nodes (16): blob, CFkey2, crypto, ct, data, fs, iv0, iv32 (+8 more)

### Community 6 - "ofb_d_test.js"
Cohesion: 0.13
Nodes (14): CFkey2, crypto, ct, data, fs, iv0, iv32, key32 (+6 more)

### Community 7 - "aes_test.js"
Cohesion: 0.14
Nodes (11): candidates, crypto, ct, data, drumlinDataX, fs, idStr, IVs (+3 more)

### Community 8 - "blob_aes.js"
Cohesion: 0.17
Nodes (11): blob, CFkey2, crypto, ct, data, fs, ivCands, keyA (+3 more)

### Community 9 - "brute_phase.js"
Cohesion: 0.17
Nodes (11): CFkey2, data, found, fs, iv32, key32, keyA, keyB (+3 more)

### Community 10 - "combo_test.js"
Cohesion: 0.17
Nodes (11): CFkey1, CFkey2, combos, CPkey2, ct, data, fs, keyA (+3 more)

### Community 11 - "ks2.js"
Cohesion: 0.25
Nodes (7): cnt, ct, data, fs, known, ks, r8

### Community 12 - "cfb_test.js"
Cohesion: 0.20
Nodes (9): CFkey2, crypto, ct, data, fs, iv32, key32, ks1 (+1 more)

### Community 13 - "HANDOFF — graphify graph for javelina"
Cohesion: 0.33
Nodes (5): HANDOFF — graphify graph for javelina, How to read the graph, Known gaps, not bugs, What was done, Why `.graphifyignore` exists

### Community 14 - "values_dump.js"
Cohesion: 0.29
Nodes (6): data, fs, keyA, out, pt, vb

### Community 15 - "Javelin3 DRM sample corpus"
Cohesion: 0.33
Nodes (5): Files, Format observations (all 258 files), Javelin3 DRM sample corpus, Known-good free sample, Sources

### Community 16 - "xor_test.js"
Cohesion: 0.33
Nodes (5): ct, data, fs, keyA, keyB

### Community 20 - "sys"
Cohesion: 0.08
Nodes (7): PROCESSENTRY32, check(), head(), decrypt(), check(), decrypt(), ks_stream()

### Community 25 - "ref_fs"
Cohesion: 0.05
Nodes (31): cands, CFkey1, CFkey2, CPkey2, ct, data, fs, iv0 (+23 more)

## Knowledge Gaps
- **40 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `dump_pe()` connect `struct` to `re`?**
  _High betweenness centrality (0.001) - this node is a cross-community bridge._
- **Should `re` be split into smaller, more focused modules?**
  _Cohesion score 0.12878787878787878 - nodes in this community are weakly interconnected._
- **Should `matrix2.js` be split into smaller, more focused modules?**
  _Cohesion score 0.10526315789473684 - nodes in this community are weakly interconnected._
- **Should `struct` be split into smaller, more focused modules?**
  _Cohesion score 0.10666666666666667 - nodes in this community are weakly interconnected._
- **Should `aes_derived.js` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `key32_ivs.js` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._
- **Should `ofb_d_test.js` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._