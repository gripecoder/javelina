const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(1810);
const TARGET = Buffer.from("%PDF-1.7", "latin1");
const CFkey2 = Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex");
const CFkey1 = Buffer.from("BABA1811ADEAB44C0804C00E24B32449", "hex");
const CPkey2 = Buffer.from("44CCAA0A0D00059C9999C99E29932999", "hex");
const keyRes = Buffer.from("11011811ADEAB44C0804C00E24B32449", "hex");
const keyA = Buffer.concat([CFkey1, CPkey2]);       // 0x1012F0C0
const keyB = Buffer.concat([CPkey2, keyRes]);       // 0x1012F0E0

const combos = {
  "CFkey2^keyA": null,
  "CFkey2^keyB": null,
  "CFkey1^keyB": null,
  "CFkey2^keyA^keyB": null,
};
for (const [name, _] of Object.entries(combos)) {
  const k1 = name.includes("CFkey2") ? CFkey2 : CFkey1;
  const parts = [];
  if (name.includes("keyA")) parts.push(keyA);
  if (name.includes("keyB")) parts.push(keyB);
  let hit = false;
  for (let i = 0; i < 7 && !hit; i++) {
    let v = ct[i];
    v ^= k1[i % 16];
    for (const p of parts) v ^= p[i % p.length];
    if (v === TARGET[i]) { if (i === 6) hit = true; } else break;
  }
  if (hit) {
    console.log("HIT", name);
    const pt = Buffer.alloc(ct.length);
    for (let i = 0; i < ct.length; i++) {
      let v = ct[i] ^ k1[i % 16];
      for (const p of parts) v ^= p[i % p.length];
      pt[i] = v;
    }
    fs.writeFileSync("%USERPROFILE%\\Documents\\github\\rea\\mountainmaps\\out_" + name.replace(/\W/g, "_") + ".pdf", pt);
  }
}
console.log("done");
