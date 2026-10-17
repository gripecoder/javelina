const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(1810);
const known = Buffer.from("%PDF-1.7\r%âãÏÓ\r\n" + "1 0 obj\r\n<< /Li" + "nearized 1 /L 1", "latin1");
const ks = Buffer.alloc(known.length);
for (let i = 0; i < known.length; i++) ks[i] = ct[i] ^ known[i];
for (let i = 0; i < 3; i++) console.log(`ks[${i * 16}:${i * 16 + 16}]:`, ks.subarray(i * 16, i * 16 + 16).toString("hex"));
console.log("ks1^ks0:", Buffer.from(ks.subarray(16, 32).map((b, i) => b ^ ks[i])).toString("hex"));
console.log("ks2^ks1:", Buffer.from(ks.subarray(32, 48).map((b, i) => b ^ ks[16 + i])).toString("hex"));
// check ks2 == ks0?
console.log("ks2==ks0:", ks.subarray(32, 48).equals(ks.subarray(0, 16)));
// counter-style: ks[i] = ks0 ^ i?
const cnt = Buffer.alloc(16);
for (let i = 0; i < 16; i++) cnt[i] = ks[i] ^ (i & 0xff);
console.log("ks0^counter:", cnt.toString("hex"));
// maybe keystream = CFkey2 rotated?
const r8 = Buffer.from([...ks.subarray(0, 16)].slice(-1).concat([...ks.subarray(0, 16)].slice(0, -1)));
console.log("ks0 rotL1:", r8.toString("hex"));
