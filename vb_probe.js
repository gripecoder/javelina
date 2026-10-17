const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const vb = data.subarray(0x90, 0x712);
const keyA = Buffer.from("BABA1811ADEAB44C0804C00E24B32449" + "44CCAA0A0D00059C9999C99E29932999", "hex");
console.log("vb[0:128]:", vb.subarray(0, 128).toString("hex"));

const variants = {
  "K0only": keyA.subarray(0, 16),
  "K1only": keyA.subarray(16, 32),
  "K0K1alt16": Buffer.alloc(32),
};
for (let i = 0; i < 16; i++) { variants.K0K1alt16[i] = keyA[i]; variants.K0K1alt16[16 + i] = keyA[16 + i]; }

for (const [name, key] of Object.entries(variants)) {
  const pt = Buffer.from(vb.subarray(0, 128).map((b, i) => b ^ key[i % key.length]));
  console.log(name, ":", JSON.stringify(pt.toString("latin1")));
}
