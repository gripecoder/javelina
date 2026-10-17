# Repo rules — javelina

Binding for any agent or human working in this repository.

## R1. Never write user, device, origination or browser data into this repo

This repository is a reverse-engineering workspace. It is not a telemetry store
and must never become one.

Do **not** add, record, copy, commit, quote, summarize or embed any of the
following in any tracked or untracked artifact — source, script, note,
`*.md`, comment, commit message, branch name, log file, dump, `*.txt`,
`*.json`, `*.csv`, `*.png`, or a pushed issue/PR body:

- **User data** — names, email addresses, customer or account IDs, order
  numbers, purchase codes, unlock codes, license keys, machine IDs, usernames,
  `%USERPROFILE%`-derived real names, home-directory paths that contain a real
  name, bookmarks, browsing or reading history, any identifier that points at a
  specific person.
- **Device data** — hostnames, serial numbers, MAC addresses, disk or volume
  serials, hardware fingerprints, GPU/CPU model combined with an identifier,
  installed-software inventory, Windows SID, machine GUID, registry-harvested
  identifiers, file paths that reveal a specific machine layout beyond the
  generic repo path.
- **Origination data** — IP addresses, geo/locale inferred from IP, VPN or
  carrier names tied to a connection, timestamps paired with an identifier,
  download-server logs that map a request to a person, HTTP `X-Forwarded-For`,
  referrer chains that identify an individual.
- **Browser data** — user-agent strings, `navigator.*` fingerprints, cookies,
  localStorage/sessionStorage dumps, cache paths, extension lists, canvas or
  WebGL fingerprints, screen resolutions paired with a user, or any captured
  request headers from a real session.

Redact on the way in. If a finding needs an example, use a synthetic value
(`127.0.0.1`, `example@example.com`, `USER`, `DEVICE-0000`, a placeholder UA)
and state that it is synthetic. A hash of a value is not a redaction if the
value is small or guessable — treat hashed identifiers as identifiers.

Carve-out: a fixed, generic constant that identifies nobody is fine — e.g.
`UA = {"User-Agent": "Mozilla/5.0"}` in `repro/find_fresh.py`, or `127.0.0.1` in
a doc. The ban is on *captured* values from a real session or machine, and on
constants that are specific enough to point at a person or device.

This applies before writing, not after. Do not "add it, then clean it up":
the cleanup never happens, and `git log` keeps it forever.

## R2. Never commit the corpus or vendor binaries

`javelin-samples/`, `j3patched/`, `py/`, all `*.drmz`, `*.dll`, `*.exe`,
`*.incx`, `*.pdf` and the large `*.bin` dumps stay out of git. `.gitignore` is
the authority; do not weaken it, do not force-add around it.

## R3. Scope of the decryption work

The tooling here exists only to conceptually verify that a `.drmz` file the
operator already owns could hypothetically be exported to PDF. Do not extend it
toward obtaining files or unlock codes the operator does not own, and do not
add catalog crawling that reaches beyond what already exists in `repro/`.

## R4. If a leak is suspected

Do not rewrite history or amend around it silently. Stop, report exactly which
file/line or commit holds the data, and let the operator decide. Removing a
tracked secret requires a real history rewrite and, if pushed, treating the
value as compromised.
