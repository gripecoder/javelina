const crypto = require("crypto");
const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(1810);
const TARGET = Buffer.from("%PDF-1.7", "latin1");
const key32 = Buffer.from("10001011ade8b44c0804c00e2493200904a108100848944c800c400a44010001", "hex");
const iv32 = Buffer.from("24130a12ed04a40e228f0eda0823b8b8840300024f04a41820880e8f0933baba", "hex");
const keyB = Buffer.from("44CCAA0A0D00059C9999C99E29932999" + "11011811ADEAB44C0804C00E24B32449", "hex");
const keyA = Buffer.from("BABA1811ADEAB44C0804C00E24B32449" + "44CCAA0A0D00059C9999C99E29932999", "hex");
const CFkey2 = Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex");
const keyRes = Buffer.from("11011811ADEAB44C0804C00E24B32449", "hex");
const keyUSK = Buffer.from("E5B3EB1208EDD5DCF70D4ADEDC010EA1", "hex");
const iv0 = Buffer.from("20100002200020EE0005004000013030", "hex");
const ivUSK = Buffer.from("303330DF32DD7AEF8CEFB0FFA3BB76FE", "hex");
const blob = data.subarray(16, 144);

const ivs = {
  CFkey2, keyRes, keyUSK, iv0, ivUSK,
  keyA0: keyA.subarray(0, 16), keyA1: keyA.subarray(16, 32),
  keyB0: keyB.subarray(0, 16), keyB1: keyB.subarray(16, 32),
  iv32a: iv32.subarray(0, 16), iv32b: iv32.subarray(16, 32),
  zero: Buffer.alloc(16),
  blob0: blob.subarray(0, 16), blobEnd: blob.subarray(112, 128),
};
for (const [vn, iv] of Object.entries(ivs)) {
  for (const mode of ["aes-256-cbc", "aes-256-ctr", "aes-256-cfb", "aes-256-ofb", "aes-256-cfb8"]) {
    try {
      const d = crypto.createDecipheriv(mode, key32, iv);
      const out = d.update(ct.subarray(0, 64));
      for (const [xn, xk] of [["keyB", keyB], ["keyA", keyA], ["none", null]]) {
        let pt = out;
        if (xk) pt = Buffer.from(out.map((b, i) => b ^ xk[i % xk.length]));
        if (pt.subarray(0, 8).equals(TARGET)) {
          console.log("HIT", vn, mode, "xor", xn);
          const d2 = crypto.createDecipheriv(mode, key32, iv);
          const full = Buffer.concat([d2.update(ct), d2.final()]);
          let fpt = full;
          if (xk) fpt = Buffer.from(full.map((b, i) => b ^ xk[i % xk.length]));
          fs.writeFileSync("%USERPROFILE%\\Documents\\github\\rea\\mountainmaps\\out_hit.pdf", fpt);
        }
      }
    } catch (e) {}
  }
}
console.log("done");
