const crypto = require("crypto");
const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(1810);
const TARGET = Buffer.from("%PDF-1.7", "latin1");

const key0_32 = Buffer.from("40802802000000909009099020922108" + "05A0000010A000018008000440000500", "hex");
const CFkey2_32 = Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111" + "11011811ADEAB44C0804C00E24B32449", "hex");
const keyRes_32 = Buffer.from("11011811ADEAB44C0804C00E24B32449" + "E5B3EB1208EDD5DCF70D4ADEDC010EA1", "hex");
const iv0_32 = Buffer.from("20100002200020EE0005004000013030" + "400340020B0005080100060700000008", "hex");
const iv1_32 = Buffer.from("14231A1DDFD4D4E1A6CAAEBFA93ACACA" + "C43C4A14E414A317279928D8893BBBB2", "hex");
const iv2_32 = Buffer.from("24132AD2ED0DAEEE2AAF1EDA0AA3BCBC" + "C4C344424FA4A51829888E8F79B3BABB", "hex");

const key32 = Buffer.alloc(32);
for (let i = 0; i < 32; i++) key32[i] = (CFkey2_32[i] ^ key0_32[i]) & keyRes_32[i];
const iv32 = Buffer.alloc(32);
for (let i = 0; i < 32; i++) iv32[i] = (iv1_32[i] ^ iv0_32[i]) & iv2_32[i];
console.log("derived key32:", key32.toString("hex"));
console.log("derived iv32 :", iv32.toString("hex"));

const keyA = Buffer.from("BABA1811ADEAB44C0804C00E24B32449" + "44CCAA0A0D00059C9999C99E29932999", "hex");
const keyB = Buffer.from("44CCAA0A0D00059C9999C99E29932999" + "11011811ADEAB44C0804C00E24B32449", "hex");
const CFkey2 = Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex");

function tryDec(name, mode, key, iv) {
  try {
    const d = crypto.createDecipheriv(mode, key, mode.includes("ecb") ? null : iv);
    let out = Buffer.concat([d.update(ct), d.final()]);
    for (const [xn, xk] of [["keyA", keyA], ["keyB", keyB], ["CFkey2", CFkey2], ["none", null]]) {
      let pt = out;
      if (xk) {
        pt = Buffer.alloc(out.length);
        for (let i = 0; i < out.length; i++) pt[i] = out[i] ^ xk[i % xk.length];
      }
      if (pt.subarray(0, 8).equals(TARGET)) {
        console.log("HIT", name, "+xor", xn);
        fs.writeFileSync("%USERPROFILE%\\Documents\\github\\rea\\mountainmaps\\out_" + name.replace(/[^\w]/g, "_") + "_" + xn + ".pdf", pt);
      }
    }
  } catch (e) { /* */ }
}

const ivs = [
  ["iv0half", iv32.subarray(0, 16)],
  ["iv1half", iv32.subarray(16, 32)],
  ["zero", Buffer.alloc(16)],
];
const keys = [
  ["k256", key32],
  ["k128a", key32.subarray(0, 16)],
  ["k128b", key32.subarray(16, 32)],
];
for (const [kn, k] of keys) {
  const bits = k.length * 8;
  for (const [vn, iv] of ivs) {
    for (const mode of [`aes-${bits}-cbc`, `aes-${bits}-ctr`, `aes-${bits}-cfb`, `aes-${bits}-ofb`, `aes-${bits}-cfb8`]) {
      tryDec(`${kn}-${vn}-${mode}`, mode, k, iv);
    }
  }
  tryDec(`${kn}-ecb`, `aes-${bits}-ecb`, k, null);
}
console.log("done");
