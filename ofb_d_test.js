const crypto = require("crypto");
const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(1810);
const CFkey2 = Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex");
const ks1 = Buffer.from("59b5afc558435393eca115a95b2067", "hex");
const key32 = Buffer.from("10001011ade8b44c0804c00e2493200904a108100848944c800c400a44010001", "hex");
const iv32 = Buffer.from("24130a12ed04a40e228f0eda0823b8b8840300024f04a41820880e8f0933baba", "hex");
const keyA = Buffer.from("BABA1811ADEAB44C0804C00E24B32449" + "44CCAA0A0D00059C9999C99E29932999", "hex");
const keyB = Buffer.from("44CCAA0A0D00059C9999C99E29932999" + "11011811ADEAB44C0804C00E24B32449", "hex");
const keyRes = Buffer.from("11011811ADEAB44C0804C00E24B32449", "hex");
const keyUSK = Buffer.from("E5B3EB1208EDD5DCF70D4ADEDC010EA1", "hex");
const iv0 = Buffer.from("20100002200020EE0005004000013030", "hex");

const keys = { key32, key32a: key32.subarray(0, 16), key32b: key32.subarray(16, 32),
  keyA0: keyA.subarray(0, 16), keyA1: keyA.subarray(16, 32),
  keyB0: keyB.subarray(0, 16), keyB1: keyB.subarray(16, 32),
  keyRes, keyUSK, iv0, iv32a: iv32.subarray(0, 16), iv32b: iv32.subarray(16, 32),
  CFkey2 };

for (const [kn, k] of Object.entries(keys)) {
  const algo = `aes-${k.length * 8}-ecb`;
  const d1 = crypto.createDecipheriv(algo, k, null);
  const r1 = d1.update(CFkey2);
  if (r1.equals(ks1)) console.log("OFB-D: D_K(CFkey2) == ks1, key =", kn);
  const d2 = crypto.createDecipheriv(algo, k, null);
  const r2 = d2.update(ct.subarray(0, 16));
  if (r2.equals(ks1)) console.log("CFB-D: D_K(ct0) == ks1, key =", kn);
  const e1 = crypto.createCipheriv(algo, k, null);
  const r3 = e1.update(CFkey2);
  if (r3.equals(ks1)) console.log("OFB-E: E_K(CFkey2) == ks1, key =", kn);
  const e2 = crypto.createCipheriv(algo, k, null);
  const r4 = e2.update(ct.subarray(0, 16));
  if (r4.equals(ks1)) console.log("CFB-E: E_K(ct0) == ks1, key =", kn);
}
console.log("done");
