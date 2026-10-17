const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const keyA = Buffer.from("BABA1811ADEAB44C0804C00E24B32449" + "44CCAA0A0D00059C9999C99E29932999", "hex");
const keyB = Buffer.from("44CCAA0A0D00059C9999C99E29932999" + "11011811ADEAB44C0804C00E24B32449", "hex");

// values block 0x90..0x712
const vb = data.subarray(0x90, 0x712);
for (const [name, key] of [["A", keyA], ["B", keyB]]) {
  const pt = Buffer.from(vb.map((b, i) => b ^ key[i % 32]));
  let printable = 0;
  for (const b of pt) if (b >= 32 && b < 127) printable++;
  console.log("values XOR", name, "printable ratio", (printable / pt.length).toFixed(3));
  console.log("  head:", JSON.stringify(pt.subarray(0, 96).toString("latin1")));
}

// PDF data at 0x712
const ct = data.subarray(0x712);
for (const [name, key] of [["A", keyA], ["B", keyB]]) {
  const pt = Buffer.alloc(ct.length);
  for (let i = 0; i < ct.length; i++) pt[i] = ct[i] ^ key[i % 32];
  const head = pt.subarray(0, 24).toString("latin1");
  const tail = pt.subarray(-96).toString("latin1");
  console.log("pdf XOR", name, "head:", JSON.stringify(head));
  console.log("  tail:", JSON.stringify(tail));
  if (head.startsWith("%PDF")) {
    fs.writeFileSync("%USERPROFILE%\\Documents\\github\\rea\\mountainmaps\\out_" + name + ".pdf", pt);
    console.log("WROTE out_" + name + ".pdf");
  }
}
