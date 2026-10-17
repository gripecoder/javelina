# HANDOFF — graphify graph for javelina

State as of the first graph build. Read this before trusting `graphify-out/`.

## What was done

1. `graphify extract . --code-only --no-cluster --force` — AST only, no LLM, no API cost.
2. `graphify cluster-only . --no-label --no-viz` — Leiden clustering, community naming skipped.
3. `graphify export html` — `graphify-out/graph.html`, self-contained.
4. `graphify hook install` — post-commit / post-checkout / post-merge hooks, plus the
   `merge=graphify` driver registered in git config, so a commit refreshes the code graph for free.

Result: 339 nodes, 353 edges, 60 communities, 100% EXTRACTED, 0% INFERRED.

## Why `.graphifyignore` exists

The first pass indexed 140 code files, 57 of them the vendored capstone bindings under
`py/`. Their symbols were every top hub (`copy_ctypes_list`, `CsError`, `CsInsn`, `Cs`,
`Arm64Op`, …), which hides this repo's own code. `.graphifyignore` now excludes `py/`,
`tmp/`, `__pycache__/` and the binary containers (`*.drmz`, `*.dll`, `*.pdf`, `*.bin`).

`tmp/` also held `pip-build-tracker-*` / `pip-install-*` directories whose ACLs deny
access: the first run emitted `[WinError 5] Access is denied` for nine of them and had to
fall back to sequential AST extraction. Excluding `tmp/` removes both problems.

Delete `.graphifyignore` only if you want the capstone library in the graph, and expect
the hubs to be library classes again.

## Known gaps, not bugs

- **PowerShell is invisible.** The extractor models no symbols for `.ps1`, so all the
  `*.ps1` automation here (`patch_dll`, `dllimport_*`, `dump_keys`, `live_patch`, …) yields
  zero nodes. 28 of the 83 indexed files yielded no symbols for this reason. Do not try to
  answer PowerShell questions with the graph; use `grep` and `read`.
- **Community names are `Community N` placeholders.** Naming needs an LLM backend, and this
  machine has no `GEMINI_API_KEY`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `DEEPSEEK_API_KEY`
  or `KIMI_API_KEY` set, and no `~/.graphify` config directory (graphify cannot even create
  it: `PermissionError: [WinError 5] Access is denied: '%USERPROFILE%\.graphify'` under the
  workspace-write sandbox). Run `graphify label .` after providing a key — it spends budget.
- **286 `.drmz` / `.dll` / `.bin` files are unclassified** (no extension graphify models) and
  are not in the graph. This is an RE workspace: the corpus is loose scripts plus binaries,
  so a code graph can only ever cover part of it.
- `graph.html` was built without clustering labels, so node colours are meaningless beyond
  cluster membership.

## How to read the graph

MCP tools answer for this repo — pass the absolute path:

```
mcp__graphify__query_graph     project_path: <repo>
mcp__graphify__graph_stats / god_nodes / shortest_path / get_neighbors
```

Verified: `graph_stats` returned 339/353/60 for that path. `graphify check-update .` prints
nothing, i.e. nothing is pending.

Avoid the CLI subcommands that hang on large graphs (`query`, `explain`, `path --undirected`);
the safe ones are `god-nodes`, `affected`, `check-update`, `diagnose`.

---

# HANDOFF — Javelin3 `.drmz` decryption, reconstructed and verified 2026-10-17

## The scheme

`.drmz` layout: 8-byte magic `{DRMPDK}`, u32 version at 8, u32 header length at
offset 12. The PDF payload begins **exactly at the header length** (`start = u32 at 12`),
not at 16. The payload is XORed with a **32-byte repeating keystream**, made of two
constant 16-byte blocks used in alternation:

```
DEDAFF1FFDEDBDDCD80DCDDEDD011111   51ACAFD1171119F184F724B548434219
```

So byte `i` of the payload is XORed with `KEY[i & 31]`. The keystream is
**constant across every file and every issuer** — it is not keyed per file, per
customer or per download. There is no AES involved: the earlier exploration
(`aes_derived.js`, `key32_ivs.js`, `ofb_d_test.js`, …) was chasing the key material
dumped out of the reader's key schedules, and the answer turned out to be a plain
static XOR stream.

Verified: `repro/xor32.py` produces a byte-identical copy of
`exported_auto.pdf` (`MountainDirectoryCombined.drmz`, header 1810, 40,135,745 bytes,
785 pages) — `identical True` on a full memcmp.

## Why the earlier 16-byte script looked right and was not

`decrypt_final.js` decrypts with only the first block
(`DEDAFF1FFDEDBDDCD80DCDDEDD011111`, period 16). That is correct on **every second
16-byte block only**: with a period-16 key, exactly 50% of the bytes come out right
and the file stays structurally broken (`startxref` missing, pypdf `startxref not
found`). Measured on the MountainDirectory file: 20,067,873 of 40,135,745 bytes match
the true plaintext, mismatching runs never exceed 32 bytes, and the per-block check
gives an alternating `K.K.K.` pattern. Adding the second block to a 32-byte cycle
fixes the remaining half.

Do not "fix" this by deleting the second block, and do not re-derive the keys from a
single file's plaintext alone — a 16-byte known plaintext (`%PDF-1.7\r%\xe2\xe3\xcf\xd3\r\n`)
recovers both blocks only because it is exactly the 16-byte boundary; keep both.

## Reproducibility result

- `repro/scan_all.py` — all **258 unique** corpus files (`javelin-samples/*.drmz`
  and `*.DRMZ`) pass: `%PDF-1.x` head, `%%EOF` and `startxref` in the tail, `endobj`
  count > 5. 232 s, in-memory, nothing written to disk.
- 12 files picked at random were parsed with pypdf 6.18.1 and gave real page counts
  and page-1 text, e.g. `Rife_Handbook_6th_Ed_2025` 1200 pages, `Acupuncture-in-the-
  Treatment-of-Childen` 616 pages, `BHP83` 255 pages, `MIJournal-5-9-2025` 24 pages.
- A **fresh download** from the vendor catalog
  (`https://www.drumlinsecurity.com/orders/edubooks/drmz/Ingenier%C3%ADa_de_Prompt_v1.0.drmz`,
  10,228,721 bytes, sha256[0:16] `5b621630d7eb70e1`) decrypts to a 106-page PDF and is
  byte-identical to the corpus copy of the same book, which confirms the keystream is
  static rather than per-download.
- Nothing new is left to harvest: a full catalog rescan (`repro/find_fresh.py`, 20
  catalogs + 7 catalog zips, 331 URLs) finds only `pharmaguide.drmz` (HTTP 404) and an
  accent-encoded duplicate of `Ingenieria_de_Prompt_v1.0.drmz`. `repro/fresh_urls.txt`
  holds the raw candidates.

## Traps

- `javelin-samples/*.drmz` plus `*.DRMZ` globs double-count the same 258 files on
  Windows because the uppercase set matches both patterns. Dedupe by
  `os.path.normcase` before reporting counts.
- The payload is large (3.36 GB corpus); `xor32.decrypt()` holds it all in memory and
  runs a Python-level XOR. That is ~230 s for the whole corpus. Validate head/tail and
  `endobj` counts in memory rather than writing 3.4 GB of PDFs.
- `probe_drmz.py`, `probe_drmz`-style offsets and every `*.js` script under the repo
  root hardcode `%USERPROFILE%\Documents\maps\MountainDirectory\...`. That directory
  still exists, but `%USERPROFILE%\Documents\github\rea\mountainmaps` — where
  `decrypt_final.js` writes its output — is now empty, so those scripts fail on write.
- `MountainDirectoryCombined.pdf` and `exported_auto.pdf` at the repo root are the
  same 40,135,745-byte file (one is the older copy). Both are the verified output of
  the 32-byte keystream above.

## Use it

```
python repro\xor32.py javelin-samples\BHP83.drmz   # prints head/eof/xref/obj + pypdf pages
python repro\scan_all.py                          # whole-corpus regression, ~4 min
python repro\find_fresh.py                        # is there anything new online?
```
