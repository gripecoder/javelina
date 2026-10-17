const crypto = require("crypto");
const fs = require("fs");

const DRMZ = "%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz";
const data = fs.readFileSync(DRMZ);
const ct = data.subarray(17);

// key material candidates
const drumlinDataX = Buffer.from("555895c34bfc5c6578ee57f7e5e7d0cd9af13c8394ab88bebd1a65b9bba526072a8b7e44d44d9283f7fb722156da7854f21731fe9b625ca7e1116812283c6bdb", "hex");
const keycodeStr = Buffer.from("u~*e|wt{,");
const idStr = Buffer.from("37817187");
const xStr = Buffer.from("1280745340");
const candidates = [];
function add(name, buf) {
  candidates.push([name, buf]);
  candidates.push([name + "-md5", crypto.createHash("md5").update(buf).digest()]);
  candidates.push([name + "-sha1", crypto.createHash("sha1").update(buf).digest()]);
  candidates.push([name + "-sha256", crypto.createHash("sha256").update(buf).digest()]);
}
add("DrumlinDataX", drumlinDataX);
add("DrumlinDataX[0:32]", drumlinDataX.subarray(0, 32));
add("DrumlinDataX[32:64]", drumlinDataX.subarray(32, 64));
add("DrumlinDataX[0:16]", drumlinDataX.subarray(0, 16));
add("DrumlinDataX[16:32]", drumlinDataX.subarray(16, 32));
add("keycode", keycodeStr);
add("8474_ID", idStr);
add("DrumlinX_", xStr);

const IVs = [];
function addIv(name, buf) { IVs.push([name, buf]); }
addIv("zero16", Buffer.alloc(16));
addIv("ct[0:16]", ct.subarray(0, 16));
addIv("file[0:16]", data.subarray(0, 16));
addIv("file[16:32]", data.subarray(16, 32));
addIv("file[8:24]", data.subarray(8, 24));
addIv("fld+zeros", Buffer.concat([data.subarray(8, 16), Buffer.alloc(8)]));

const TARGET = "%PDF-1.7";
const KEYSTREAM8 = Buffer.from("bea6a978cab66b23", "hex");

for (const [kname, kbuf] of candidates) {
  for (const bits of [128, 256]) {
    if (kbuf.length < bits / 8) continue;
    const key = bits === 128 ? kbuf.subarray(0, 16) : kbuf.subarray(0, 32);
    for (const [ivname, iv] of IVs) {
      for (const algo of ["aes-128-cbc", "aes-256-cbc"]) {
        if (algo.startsWith("aes-128") !== (bits === 128)) continue;
        try {
          const d = crypto.createDecipheriv(algo, key, iv);
          const out = Buffer.concat([d.update(ct), d.final()]);
          if (out.subarray(0, 8).toString("latin1") === TARGET) {
            console.log("HIT", kname, bits, ivname, algo);
          }
        } catch (e) {}
      }
    }
  }
  // keystream check for CTR family
  for (const bits of [128, 256]) {
    if (kbuf.length < bits / 8) continue;
    const key = bits === 128 ? kbuf.subarray(0, 16) : kbuf.subarray(0, 32);
    const algo = `aes-${bits}-ecb`;
    const ks = crypto.createCipheriv(algo, key, null).update(Buffer.alloc(16));
    if (ks.subarray(0, 8).equals(KEYSTREAM8)) {
      console.log("KEYSTREAM MATCH ECB-zero-block", kname, bits, ks.toString("hex"));
    }
    const ks2 = crypto.createCipheriv(algo, key, null).update(ct.subarray(0, 16));
    if (ks2.subarray(0, 8).equals(KEYSTREAM8)) {
      console.log("KEYSTREAM MATCH ECB-ct0", kname, bits);
    }
  }
  // XOR with key repeated
  for (const rep of [kbuf, kbuf.subarray(0, 16), kbuf.subarray(0, 32)]) {
    if (rep.length === 0) continue;
    let ok = true;
    for (let i = 0; i < 8; i++) if ((ct[i] ^ rep[i % rep.length]) !== TARGET.charCodeAt(i)) ok = false;
    if (ok) console.log("XOR REPEAT MATCH", kname, rep.length);
  }
}
console.log("done");
