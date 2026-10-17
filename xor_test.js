const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(17);

const keyA = Buffer.from("BABA1811ADEAB44C0804C00E24B32449" + "44CCAA0A0D00059C9999C99E29932999", "hex"); // CFkey1 + CPkey2 @0x1012F0C0
const keyB = Buffer.from("44CCAA0A0D00059C9999C99E29932999" + "11011811ADEAB44C0804C00E24B32449", "hex"); // CPkey2 + keyRes @0x1012F0E0

for (const [name, key] of [["A_CFkey1+CPkey2", keyA], ["B_CPkey2+keyRes", keyB]]) {
  const pt = Buffer.alloc(ct.length);
  for (let i = 0; i < ct.length; i++) pt[i] = ct[i] ^ key[i % 32];
  const head = pt.subarray(0, 24).toString("latin1");
  const tail = pt.subarray(-64).toString("latin1");
  console.log(name, "head:", JSON.stringify(head), "tail:", JSON.stringify(tail));
  if (head.startsWith("%PDF")) {
    fs.writeFileSync("%USERPROFILE%\\Documents\\github\\rea\\mountainmaps\\out_" + name + ".pdf", pt);
    console.log("WROTE out_" + name + ".pdf, size", pt.length);
  }
}
