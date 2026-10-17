const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const keyA = Buffer.from("BABA1811ADEAB44C0804C00E24B32449" + "44CCAA0A0D00059C9999C99E29932999", "hex");
const vb = data.subarray(0x90, 0x712);
const pt = Buffer.from(vb.map((b, i) => b ^ keyA[i % 32]));
fs.writeFileSync("%USERPROFILE%\\Documents\\github\\rea\\mountainmaps\\values_plain.bin", pt);
// hex + text dump, 32 bytes per line
let out = [];
for (let i = 0; i < pt.length; i += 16) {
  const hex = pt.subarray(i, i + 16).toString("hex");
  const txt = Array.from(pt.subarray(i, i + 16)).map(b => b >= 32 && b < 127 ? String.fromCharCode(b) : ".").join("");
  out.push(`${i.toString(16).padStart(5, "0")}  ${hex}  |${txt}|`);
}
console.log(out.join("\n"));
// file[143] + blob
console.log("file[143] (type byte):", data[143].toString(16));
console.log("blob[0:32]:", data.subarray(16, 48).toString("hex"));
console.log("blob[112:128]:", data.subarray(128, 144).toString("hex"));
