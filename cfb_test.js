const crypto = require("crypto");
const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(1810);
const TARGET = Buffer.from("%PDF-1.7", "latin1");
const CFkey2 = Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex");
const ks1 = Buffer.from("59b5afc558435393eca115a95b2067", "hex");
const key32 = Buffer.from("10001011ade8b44c0804c00e2493200904a108100848944c800c400a44010001", "hex");
const iv32 = Buffer.from("24130a12ed04a40e228f0eda0823b8b8840300024f04a41820880e8f0933baba", "hex");

// direct OFB check: E_K(CFkey2) == ks1 ?
for (const [kn, k] of [["key32", key32], ["key32a", key32.subarray(0, 16)], ["key32b", key32.subarray(16, 32)], ["iv32", iv32], ["iv32a", iv32.subarray(0, 16)], ["iv32b", iv32.subarray(16, 32)]]) {
  const c = crypto.createCipheriv(`aes-${k.length * 8}-ecb`, k, null);
  const e = c.update(CFkey2);
  if (e.equals(ks1)) console.log("OFB ks1 MATCH key =", kn);
  const e2 = c.update(ct.subarray(0, 16));
  if (e2.equals(ks1)) console.log("CFB ks1 MATCH key =", kn);
}

for (const [kn, k] of [["key32", key32], ["key32a", key32.subarray(0, 16)], ["key32b", key32.subarray(16, 32)]]) {
  const bits = k.length * 8;
  for (const mode of [`aes-${bits}-cfb`, `aes-${bits}-ofb`, `aes-${bits}-cbc`, `aes-${bits}-ctr`, `aes-${bits}-cfb8`, `aes-${bits}-cfb1`]) {
    try {
      const d = crypto.createDecipheriv(mode, k, CFkey2);
      const out = d.update(ct.subarray(0, 48));
      if (out.subarray(0, 8).equals(TARGET)) {
        console.log("HIT", kn, mode, "IV=CFkey2");
        // full decrypt
        const d2 = crypto.createDecipheriv(mode, k, CFkey2);
        const full = Buffer.concat([d2.update(ct), d2.final()]);
        fs.writeFileSync("%USERPROFILE%\\Documents\\github\\rea\\mountainmaps\\out_" + kn + "_" + mode + ".pdf", full);
      }
    } catch (e) {}
  }
}
console.log("done");
