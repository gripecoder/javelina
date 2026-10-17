const crypto = require("crypto");
const fs = require("fs");
const data = fs.readFileSync("%USERPROFILE%\\Documents\\maps\\MountainDirectory\\MountainDirectoryCombined.drmz");
const ct = data.subarray(17);
const TARGET = Buffer.from("%PDF-1.7", "latin1");

const bufs = {
  key0: Buffer.from("40802802000000909009099020922108", "hex"),
  key1: Buffer.from("1CB321122DEDBDDCD80DCDDEDD0111A1", "hex"),
  key2: Buffer.from("44CCAA0A0D00059C9999C99E29932999", "hex"),
  keyRes: Buffer.from("11011811ADEAB44C0804C00E24B32449", "hex"),
  keyUSK: Buffer.from("E5B3EB1208EDD5DCF70D4ADEDC010EA1", "hex"),
  iv0: Buffer.from("20100002200020EE0005004000013030", "hex"),
  iv1: Buffer.from("14231A1DDFD4D4E1A6CAAEBFA93ACACA", "hex"),
  iv2: Buffer.from("24132AD2ED0DAEEE2AAF1EDA0AA3BCBC", "hex"),
  ivRes: Buffer.from("ACBFFF1FFDEDBDDCD80DCDDEDD011111", "hex"),
  ivUSK: Buffer.from("303330DF32DD7AEF8CEFB0FFA3BB76FE", "hex"),
  cFiler1: Buffer.from("BABA1811ADEAB44C0804C00E24B32449", "hex"),
  cFiler2: Buffer.from("DEDAFF1FFDEDBDDCD80DCDDEDD011111", "hex"),
  keyFull: Buffer.from("4080280200000090900909902092210805A0000010A0000180080004400005001CB321122DEDBDDCD80DCDDEDD0111A15AACAFDA171A79F986F726B54803421944CCAA0A0D00059C9999C99E2993299997AC1FA817AA09F1A6AE10CCD8D04DC9B4330A12EF04A41E26CF2EDF0933BABAB4330A12EF04A41E26CF2EDF0933BABA", "hex"),
  ivFull: Buffer.from("20100002200020EE0005004000013030400340020B000508010006070000000814231A1DDFD4D4E1A6CAAEBFA93ACACAC43C4A14E414A317279928D8893BBBB224132AD2ED0DAEEE2AAF1EDA0AA3BCBCC4C344424FA4A51829888E8F79B3BABB11011811ADEAB44C0804C00E24B32449570C0FD807AA09F006FE20B008404709", "hex"),
  uskFull: Buffer.from("E5B3EB1208EDD5DCF70D4ADEDC010EA1A4AC0CDAED1A74F914F756B59C039919", "hex"),
};

function check(name, pt) {
  if (pt.subarray(0, 8).equals(TARGET)) {
    console.log("HIT:", name);
    return true;
  }
  return false;
}

// 1) XOR with repeating key, all phases, key lengths 16/32/64/128
let hits = 0;
for (const [name, k] of Object.entries(bufs)) {
  for (let len of [16, 32, 64, 128]) {
    if (k.length < len) continue;
    const kb = k.subarray(0, len);
    for (let phase = 0; phase < len; phase++) {
      const pt = Buffer.alloc(64);
      for (let i = 0; i < 64; i++) pt[i] = ct[i] ^ kb[(i + phase) % len];
      if (check(`xor ${name}[0:${len}] phase ${phase}`, pt)) hits++;
    }
  }
}

// 2) XOR with alternating key1/key2 halves
{
  const k1 = bufs.cFiler1, k2 = bufs.cFiler2;
  const alt = Buffer.alloc(32);
  for (let i = 0; i < 16; i++) { alt[i] = k1[i]; alt[16 + i] = k2[i]; }
  for (let phase = 0; phase < 32; phase++) {
    const pt = Buffer.alloc(64);
    for (let i = 0; i < 64; i++) pt[i] = ct[i] ^ alt[(i + phase) % 32];
    if (check(`xor alt key1key2 phase ${phase}`, pt)) hits++;
  }
}

// 3) AES modes with all 16-byte keys and IVs — FIRST BLOCK ONLY probe
const modes = ["aes-128-cbc", "aes-128-cfb", "aes-128-ofb", "aes-128-ctr", "aes-128-ecb", "aes-128-cfb8"];
for (const [kname, k] of Object.entries(bufs)) {
  if (k.length < 16) continue;
  for (const [ivname, iv] of Object.entries(bufs)) {
    if (iv.length < 16) continue;
    const ivb = iv.subarray(0, 16);
    for (const mode of modes) {
      try {
        const d = crypto.createDecipheriv(mode, k.subarray(0, 16), mode.includes("ecb") ? null : ivb);
        const out = d.update(ct.subarray(0, 32));
        if (check(`aes ${mode} key=${kname} iv=${ivname}`, out)) hits++;
      } catch (e) { /* */ }
    }
  }
}
console.log("hits:", hits);
