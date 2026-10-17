const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const key = Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex");
const ct = data.subarray(1810);
const pt = Buffer.alloc(ct.length);
for (let i = 0; i < ct.length; i++) pt[i] = ct[i] ^ key[i % 16];
console.log("head:", JSON.stringify(pt.subarray(0, 40).toString("latin1")));
console.log("tail:", JSON.stringify(pt.subarray(-128).toString("latin1")));
const eof = pt.indexOf(Buffer.from("%%EOF"));
console.log("%%EOF at", eof, "of", pt.length);
// count structure keywords
for (const kw of ["obj", "endobj", "stream", "endstream", "xref", "trailer", "startxref"]) {
  const n = pt.toString("latin1").split(kw).length - 1;
  console.log(kw, ":", n);
}
fs.writeFileSync("%USERPROFILE%\\Documents\\github\\rea\\mountainmaps\\MountainDirectoryCombined.pdf", pt);
console.log("saved MountainDirectoryCombined.pdf", pt.length, "bytes");
