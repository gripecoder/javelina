const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(1810);
const CFkey2 = Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex");
const keyRes = Buffer.from("11011811ADEAB44C0804C00E24B32449", "hex");
const CPkey2 = Buffer.from("44CCAA0A0D00059C9999C99E29932999", "hex");
const CFkey1 = Buffer.from("BABA1811ADEAB44C0804C00E24B32449", "hex");
const iv0 = Buffer.from("20100002200020EE0005004000013030", "hex");

const cands = {
  "CFkey2+keyRes(32B)": Buffer.concat([CFkey2, keyRes]),
  "alt CFkey2/keyRes": null,
  "alt CFkey2/CPkey2": null,
  "alt CFkey2/CFkey1": null,
  "alt CFkey2/iv0": null,
};

for (const [name, key] of Object.entries(cands)) {
  let pt;
  if (key) {
    pt = Buffer.from(ct.map((b, i) => b ^ key[i % key.length]));
  } else {
    const [evenName, oddName] = name.includes("keyRes") ? ["CFkey2", "keyRes"] :
      name.includes("CPkey2") ? ["CFkey2", "CPkey2"] :
      name.includes("CFkey1") ? ["CFkey2", "CFkey1"] : ["CFkey2", "iv0"];
    const even = { CFkey2, keyRes, CPkey2, CFkey1, iv0 }[evenName];
    const odd = { CFkey2, keyRes, CPkey2, CFkey1, iv0 }[oddName];
    pt = Buffer.alloc(ct.length);
    for (let i = 0; i < ct.length; i++) {
      const unit = Math.floor(i / 16);
      pt[i] = ct[i] ^ (unit % 2 === 0 ? even[i % 16] : odd[i % 16]);
    }
  }
  const eof = pt.indexOf(Buffer.from("%%EOF"));
  const tail = pt.subarray(-64).toString("latin1");
  console.log(name, "| %%EOF:", eof, "| head:", JSON.stringify(pt.subarray(0, 32).toString("latin1")), "| tail:", JSON.stringify(tail));
  if (eof > 0) {
    fs.writeFileSync("%USERPROFILE%\\Documents\\github\\rea\\mountainmaps\\out_" + name.replace(/[^\w]/g, "_") + ".pdf", pt);
    console.log("WROTE", name);
  }
}
