const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const keys = {
  keyA0: Buffer.from("BABA1811ADEAB44C0804C00E24B32449", "hex"),
  keyA1: Buffer.from("44CCAA0A0D00059C9999C99E29932999", "hex"),
  CFkey2: Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex"),
  keyRes: Buffer.from("11011811ADEAB44C0804C00E24B32449", "hex"),
  keyUSK: Buffer.from("E5B3EB1208EDD5DCF70D4ADEDC010EA1", "hex"),
  iv0: Buffer.from("20100002200020EE0005004000013030", "hex"),
  ivUSK: Buffer.from("303330DF32DD7AEF8CEFB0FFA3BB76FE", "hex"),
  mask32a: Buffer.from("DE01FF11FDEABD4CD804CD0EDDB31149", "hex"),
  mask32b: Buffer.from("11011811ADEAB44C0804C00E24B32449", "hex"),
};
const TARGET = Buffer.from("%PDF-1.", "latin1");
const found = [];
for (const [name, key] of Object.entries(keys)) {
  for (let phase = 0; phase < key.length; phase++) {
    const scanEnd = Math.min(data.length, 1810 + 8192);
    for (let i = 1810; i < scanEnd - 8; i++) {
      let ok = true;
      for (let j = 0; j < 7; j++) {
        if ((data[i + j] ^ key[(phase + i - 1810 + j) % key.length]) !== TARGET[j]) { ok = false; break; }
      }
      if (ok) found.push({ name, phase, offset: i });
    }
  }
}
console.log("hits:", JSON.stringify(found, null, 1));

// also: search first 200KB for %PDF under any key/phase combo (offsets < 1810 too)
for (const [name, key] of Object.entries(keys)) {
  for (let phase = 0; phase < key.length; phase++) {
    const lim = Math.min(data.length - 8, 200000);
    for (let i = 0; i < lim; i++) {
      let ok = true;
      for (let j = 0; j < 7; j++) {
        if ((data[i + j] ^ key[(phase + j) % key.length]) !== TARGET[j]) { ok = false; break; }
      }
      if (ok) found.push({ name, phase, offset: i, scan: "whole" });
    }
  }
}
console.log("hits whole-file:", JSON.stringify(found.filter(f => f.scan), null, 1));
