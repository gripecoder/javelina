const crypto = require("crypto");
const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(1810);
const TARGET = Buffer.from("%PDF-1.7", "latin1");
const CFkey2 = Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex");
const ks1 = Buffer.from("59b5afc558435393eca115a95b2067", "hex");

const keys = {
  CFkey1: "BABA1811ADEAB44C0804C00E24B32449",
  CPkey2: "44CCAA0A0D00059C9999C99E29932999",
  CFkey2: "DEDAFF1FFDEDBDDCD80DCDDEDD011111",
  keyRes: "11011811ADEAB44C0804C00E24B32449",
  keyUSK: "E5B3EB1208EDD5DCF70D4ADEDC010EA1",
  iv0: "20100002200020EE0005004000013030",
  iv2: "24132AD2ED0DAEEE2AAF1EDA0AA3BCBC",
  ivRes: "ACBFFF1FFDEDBDDCD80DCDDEDD011111",
  ivUSK: "303330DF32DD7AEF8CEFB0FFA3BB76FE",
  key0: "40802802000000909009099020922108",
  key1: "1CB321122DEDBDDCD80DCDDEDD0111A1",
  key2: "44CCAA0A0D00059C9999C99E29932999",
};
for (const [name, hex] of Object.entries(keys)) {
  const k = Buffer.from(hex, "hex");
  // OFB check: AES_K(CFkey2) == ks1 ?
  const c1 = crypto.createCipheriv("aes-128-ecb", k, null);
  const ofb1 = c1.update(CFkey2);
  if (ofb1.equals(ks1)) console.log("OFB MATCH: AES_K(CFkey2) == ks[16:32], key =", name);
  // CFB check: AES_K(ct[0:16]) == ks1 ?
  const c2 = crypto.createCipheriv("aes-128-ecb", k, null);
  const cfb1 = c2.update(ct.subarray(0, 16));
  if (cfb1.equals(ks1)) console.log("CFB MATCH: AES_K(ct0) == ks[16:32], key =", name);
  // CBC decrypt with IV=CFkey2, first block check
  try {
    const d = crypto.createDecipheriv("aes-128-cbc", k, CFkey2);
    const out = d.update(ct.subarray(0, 32));
    if (out.subarray(0, 8).equals(TARGET)) console.log("CBC IV=CFkey2 HIT key =", name);
  } catch (e) {}
  // CFB decrypt with IV=CFkey2
  try {
    const d = crypto.createDecipheriv("aes-128-cfb", k, CFkey2);
    const out = d.update(ct.subarray(0, 32));
    if (out.subarray(0, 8).equals(TARGET)) console.log("CFB IV=CFkey2 HIT key =", name);
  } catch (e) {}
  // OFB decrypt with IV=CFkey2
  try {
    const d = crypto.createDecipheriv("aes-128-ofb", k, CFkey2);
    const out = d.update(ct.subarray(0, 32));
    if (out.subarray(0, 8).equals(TARGET)) console.log("OFB IV=CFkey2 HIT key =", name);
  } catch (e) {}
  // CTR with IV=CFkey2
  try {
    const d = crypto.createDecipheriv("aes-128-ctr", k, CFkey2);
    const out = d.update(ct.subarray(0, 32));
    if (out.subarray(0, 8).equals(TARGET)) console.log("CTR IV=CFkey2 HIT key =", name);
  } catch (e) {}
}
console.log("done");
