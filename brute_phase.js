const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const TARGET = Buffer.from("%PDF-1.7", "latin1");
const keyA = Buffer.from("BABA1811ADEAB44C0804C00E24B32449" + "44CCAA0A0D00059C9999C99E29932999", "hex");
const keyB = Buffer.from("44CCAA0A0D00059C9999C99E29932999" + "11011811ADEAB44C0804C00E24B32449", "hex");
const key32 = Buffer.from("10001011ade8b44c0804c00e2493200904a108100848944c800c400a44010001", "hex");
const iv32 = Buffer.from("24130a12ed04a40e228f0eda0823b8b8840300024f04a41820880e8f0933baba", "hex");
const CFkey2 = Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex");
const maskA = Buffer.from("DE01FF11FDEABD4CD804CD0EDDB31149", "hex");
const maskB = Buffer.from("11011811ADEAB44C0804C00E24B32449", "hex");

const found = [];
for (const [name, key] of Object.entries({ keyA, keyB, key32, iv32, CFkey2, maskA, maskB })) {
  for (let phase = 0; phase < key.length; phase++) {
    const lim = Math.min(data.length - 8, 1810 + 4096);
    for (let i = 1810; i < lim; i++) {
      let ok = true;
      for (let j = 0; j < 7; j++) {
        if ((data[i + j] ^ key[(phase + i - 1810 + j) % key.length]) !== TARGET[j]) { ok = false; break; }
      }
      if (ok) found.push({ name, phase, offset: i });
    }
  }
}
console.log(JSON.stringify(found, null, 1));
