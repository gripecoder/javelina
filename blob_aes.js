const crypto = require("crypto");
const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(1810);
const TARGET = Buffer.from("%PDF-1.7", "latin1");
const blob = data.subarray(16, 144);
const keyB = Buffer.from("44CCAA0A0D00059C9999C99E29932999" + "11011811ADEAB44C0804C00E24B32449", "hex");
const keyA = Buffer.from("BABA1811ADEAB44C0804C00E24B32449" + "44CCAA0A0D00059C9999C99E29932999", "hex");
const CFkey2 = Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex");

const keyCands = {
  "blob[0:32]": blob.subarray(0, 32),
  "blob[16:48]": blob.subarray(16, 48),
  "blob[96:128]": blob.subarray(96, 128),
  "blob[112:128]x2": Buffer.concat([blob.subarray(112, 128), blob.subarray(112, 128)]),
  "blob[0:16]+blob[112:128]": Buffer.concat([blob.subarray(0, 16), blob.subarray(112, 128)]),
  "blob[0:16]": blob.subarray(0, 16),
  "blob[112:128]": blob.subarray(112, 128),
};
const ivCands = {
  "zero": Buffer.alloc(16),
  "blob[32:48]": blob.subarray(32, 48),
  "blob[48:64]": blob.subarray(48, 64),
  "blob[112:128]": blob.subarray(112, 128),
  "blob[0:16]": blob.subarray(0, 16),
  "CFkey2": CFkey2,
};

for (const [kn, k] of Object.entries(keyCands)) {
  const bits = k.length * 8;
  for (const [vn, iv] of Object.entries(ivCands)) {
    for (const mode of [`aes-${bits}-cbc`, `aes-${bits}-ctr`, `aes-${bits}-cfb`, `aes-${bits}-ofb`]) {
      try {
        const d = crypto.createDecipheriv(mode, k, iv);
        let out = Buffer.concat([d.update(ct.subarray(0, 64)), d.final()]);
        for (const [xn, xk] of [["keyB", keyB], ["keyA", keyA], ["none", null]]) {
          let pt = out;
          if (xk) pt = Buffer.from(out.map((b, i) => b ^ xk[i % xk.length]));
          if (pt.subarray(0, 8).equals(TARGET)) {
            console.log("HIT", kn, vn, mode, "xor", xn);
            // full
            const d2 = crypto.createDecipheriv(mode, k, iv);
            const full = Buffer.concat([d2.update(ct), d2.final()]);
            let fpt = full;
            if (xk) fpt = Buffer.from(full.map((b, i) => b ^ xk[i % xk.length]));
            fs.writeFileSync("%USERPROFILE%\\Documents\\github\\rea\\mountainmaps\\out_blob.pdf", fpt);
          }
        }
      } catch (e) {}
    }
  }
}
console.log("done");
