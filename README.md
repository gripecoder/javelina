# javelina

Reverse-engineering scratch around Javelin3 `.drmz` files — the containers that
Drumlin Security's reader (`Javelin3.exe`) uses for publisher-locked PDFs.

**This is not a converter, not a tool, and not a product.** It is a research
dump that got out of hand: ~90 loose scripts at the repo root, three competing
decryptors, a dozen one-shot probes with `MountainDirectory` paths hardcoded
into them, and a 3.36 GB corpus of vendor downloads that is deliberately not
tracked by git. I am not happy with it, and the honest summary is below.

## My opinion of this repository

It is a mess, and it stayed a mess because every question got answered by
writing one more script at the root instead of fixing the last one.

- **The AES branch was a waste of time.** Roughly twenty files
  (`aes_derived.js`, `aes_tables.py`, `key32_ivs.js`, `ks_derive.js`,
  `ofb_d_test.js`, `blob_aes.js`, `matrix2.js`, …) are a long, careful
  investigation of the reader's key schedule. All of it was chasing something
  that does not exist. The cipher is a 32-byte static XOR stream. There is no
  AES, no per-file key, no per-customer key, no per-download key. Those files
  are kept only as a record of a wrong turn; do not read them for the answer.
- **Half the scripts no longer run.** `probe_drmz.py`, `decrypt_final.js` and
  every other `.js` at the root write into
  `%USERPROFILE%\Documents\maps\MountainDirectory` or
  `%USERPROFILE%\Documents\github\rea\mountainmaps`, which are empty or gone.
  They were written for one afternoon's check and never generalized.
- **The PowerShell layer is unreadable and unmodelled.** `jpatch.ps1`,
  `live_patch.ps1`, `inject_ptr*.ps1`, `call_native*.ps1`, `dump_keys.ps1` and
  friends are process-poking scripts pinned to **Javelin3 3.1.0.44 /
  DrumlinRast.dll (ts 0x5d72395f)** by raw RVA, with `.NET` P/Invoke inlined
  as a here-string. Any other version silently patches the wrong byte. The
  graph build cannot even see `.ps1` files (28 of 83 indexed files produced no
  symbols), so nobody can navigate this layer.
- **There are duplicate, contradictory "final" scripts.** `decrypt_final.js`
  uses a 16-byte key and produces a structurally broken PDF that happens to
  look half-right. Do not use it. `repro/xor32.py` is the correct one.
- **Bloat.** Four `*.pdf`/`*.bin` dumps of a 40 MB title sit at the root
  (`MountainDirectoryCombined.pdf`, `exported_auto.pdf`, both the same
  40,135,745 bytes; `repro/Mukhtar-Notes.pdf`, 45 MB) plus `screen.png`,
  `values_plain.bin`, `call_native*_out.txt`, `open_init.txt`. None of it
  belongs in a repository.

So: treat what follows as lab notes, not as software.

## What this repo is actually for

One thing only:

> To conceptually verify that a `.drmz` file **you already own** — a file you
> legitimately purchased and hold a valid unlock code for — *could
> hypothetically* be exported to PDF.

That is the entire scope. The point of `repro/xor32.py` is to show that the
container is a header plus a statically obfuscated PDF payload, and that once
the payload is de-obfuscated the bytes are an ordinary PDF with a valid
`startxref`, `%%EOF` and parseable pages. It is an argument about the format,
not a keygen and not a library.

It does **not** give you rights you did not have. Buying a `.drmz` buys a
license to read it under the publisher's terms; the fact that the obfuscation
is a fixed XOR table is an observation about weak engineering, not permission
to redistribute somebody else's book. Use this on your own files, for your own
verification, and nothing else. `.gitignore` reflects that: the corpus, the
decrypted output, the vendor binaries and the patched reader copies are all
excluded and must stay excluded.

## The format, as verified

```
offset  0   8 bytes   magic "{DRMPDK}"
offset  8   u32 LE    version (2 in all 258 corpus files)
offset 12   u32 LE    header length; payload starts exactly here
offset 16             header body: zero byte, then an 8-byte per-file value
offset header_len     payload: PDF, XORed with a 32-byte repeating keystream
```

Keystream — constant across every file and every issuer, used in alternation:

```
DEDAFF1FFDEDBDDCD80DCDDEDD011111
51ACAFD1171119F184F724B548434219
```

`payload[i] ^= KEY[i & 31]`. Nothing else. No AES, no IV, no key file, no
machine binding in the payload.

Header lengths in the corpus range 1552..2038 (99 distinct values) and are not
derived from file size. The `{DRMPDK}` header carries the license material the
reader checks before it will display the file; the payload does not.

### Verification on record

- All **258 unique** corpus files (`javelin-samples/*.drmz` and `*.DRMZ`,
  deduped by `os.path.normcase`) decrypt to a `%PDF-1.x` head with `%%EOF`,
  `startxref` and ` endobj` count > 5. 232 s, in memory, nothing written.
- 12 files parsed with pypdf 6.18.1 gave real page counts and page-1 text —
  e.g. 1200, 616, 255, 24 pages.
- A fresh vendor download (`Ingeniería_de_Prompt_v1.0.drmz`, 10,228,721 bytes,
  sha256[0:16] `5b621630d7eb70e1`) decrypts to a 106-page PDF and is
  byte-identical to the corpus copy of the same title — which is what proves
  the keystream is static rather than per-download.
- `MountainDirectoryCombined.drmz` (header 1810, 785 pages) decrypts to a file
  byte-identical to `exported_auto.pdf`, 40,135,745 bytes, full `memcmp`.

See `HANDOFF.md` for the longer narrative, including why the 16-byte variant
looked convincing (it is correct on every second 16-byte block, so 50% of bytes
match and the file stays broken), and the catalog-harvest dead ends.

## Layout

Worth reading, in this order:

- `repro/xor32.py` — the whole scheme in 30 lines. `check()` prints header
  length, payload size, PDF head, `%%EOF`/`startxref` and pypdf page count;
  `-o DIR` additionally writes the decrypted PDF. This is the only script here
  I would defend.
- `repro/scan_all.py` — whole-corpus regression, ~4 min, in memory.
- `repro/find_fresh.py`, `repro/fetch_fresh.py`, `repro/catalog.py` — catalog
  enumeration, to check whether anything new exists online. It does not.
- `HANDOFF.md` — the two handoff notes: the graph build, and the format.
- `.gitignore` — the ground truth about what is deliberately absent.

Everything else is scratch. Specifically: the root `*.js` / `*.py` / `*.ps1`
files are one-shot probes; `py/` is a vendored capstone 5.0.9 (install it, do
not vendor it); `graphify-out/` is a code graph that cannot see PowerShell and
whose communities are unnamed because no LLM key is configured; `j3patched/`
holds vendor binaries and patched copies of them, untracked and never to be
published.

## If you run anything

```
python repro\xor32.py javelin-samples\BHP83.drmz    # one file, inspect
python repro\xor32.py -q <owned>.drmz -o out\       # inspect + write PDF
python repro\scan_all.py                            # corpus regression, ~4 min
```

Requirements: Python 3, `pypdf` for the page-count check. The XOR itself is
plain standard library. On 3.36 GB of corpus `decrypt()` holds the payload in
memory and runs a Python-level XOR (~230 s); validate head/tail in memory
rather than materializing gigabytes of PDFs.

## Repo rule: no personal data

See `AGENTS.md`, rule R1, and treat it as binding for humans too. No user,
device, origination or browser data goes into this repository — not into a
script, a note, a commit message, a log, or a pasted dump. No names, emails,
account/order numbers, unlock codes, machine IDs, hostnames, MAC or volume
serials, IP addresses, geo locale, user-agent strings, cookies, storage dumps or
header captures. Use synthetic placeholders (`127.0.0.1`, `example@example.com`,
`USER`, `DEVICE-0000`) and say they are synthetic. Hashing an identifier does
not launder it. Redact before writing, because `git log` never forgets.

## License / ethics

No license. The scripts are unreviewed RE scratch and are provided with no
warranty of any kind, which is the most defensible thing that can be said about
them. Do not redistribute the corpus, the decrypted PDFs, the vendor DLLs or
the patched binaries. Use only on files you already own and are entitled to
read.
