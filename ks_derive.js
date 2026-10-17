const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(1810);
const known = Buffer.from("%PDF-1.7\r%âãÏÓ\r\n" + "1 0 obj\r\n<< /Li", "latin1");
const ks = Buffer.alloc(known.length);
for (let i = 0; i < known.length; i++) ks[i] = ct[i] ^ known[i];
console.log("ks[0:32]:", ks.toString("hex"));

const bufs = {
  CFkey1: "BABA1811ADEAB44C0804C00E24B32449",
  CPkey2: "44CCAA0A0D00059C9999C99E29932999",
  CFkey2: "DEDAFF1FFDEDBDDCD80DCDDEDD011111",
  keyRes: "11011811ADEAB44C0804C00E24B32449",
  keyUSK: "E5B3EB1208EDD5DCF70D4ADEDC010EA1",
  iv0: "20100002200020EE0005004000013030",
  iv1: "14231A1DDFD4D4E1A6CAAEBFA93ACACA",
  iv2: "24132AD2ED0DAEEE2AAF1EDA0AA3BCBC",
  ivRes: "ACBFFF1FFDEDBDDCD80DCDDEDD011111",
  ivUSK: "303330DF32DD7AEF8CEFB0FFA3BB76FE",
  key0: "40802802000000909009099020922108",
  key1: "1CB321122DEDBDDCD80DCDDEDD0111A1",
  key2: "44CCAA0A0D00059C9999C99E29932999",
  X1: "05A0000010A000018008000440000500",
  X2: "5AACAFDA171A79F986F726B548034219",
  X3: "97AC1FA817AA09F1A6AE10CCD8D04DC9",
  X4: "B4330A12EF04A41E26CF2EDF0933BABA",
};
for (const [name, hex] of Object.entries(bufs)) {
  const b = Buffer.from(hex, "hex");
  for (let ph = 0; ph < 16; ph++) {
    let ok = true;
    for (let j = 0; j < 16; j++) if (ks[16 + j] !== b[(ph + j) % 16]) { ok = false; break; }
    if (ok) console.log("ks[16:32] == ", name, "phase", ph);
  }
}
// print ks[16:32] and neighbors' XOR diffs
console.log("ks[16:32]:", ks.subarray(16).toString("hex"));
const cfk2 = Buffer.from(bufs.CFkey2, "hex");
const diff = Buffer.alloc(16);
for (let i = 0; i < 16; i++) diff[i] = ks[16 + i] ^ cfk2[i];
console.log("ks[16:32]^CFkey2:", diff.toString("hex"));
