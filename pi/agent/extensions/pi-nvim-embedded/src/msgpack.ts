/**
 * Minimal msgpack encode/decode for neovim RPC.
 * Handles: nil, bool, int, float64, string, bin, array, map, ext.
 */

export function encode(value: unknown): Buffer {
  const parts: Buffer[] = [];
  enc(value, parts);
  return Buffer.concat(parts);
}

function enc(v: unknown, p: Buffer[]): void {
  if (v === null || v === undefined) { p.push(B1(0xc0)); return; }
  if (v === false) { p.push(B1(0xc2)); return; }
  if (v === true) { p.push(B1(0xc3)); return; }
  if (typeof v === "number") { encNum(v, p); return; }
  if (typeof v === "string") { encStr(v, p); return; }
  if (Buffer.isBuffer(v)) { encBin(v, p); return; }
  if (Array.isArray(v)) { encArr(v, p); return; }
  if (typeof v === "object") { encMap(v as Record<string, unknown>, p); return; }
  throw new Error(`msgpack: cannot encode ${typeof v}`);
}

function B1(b: number) { return Buffer.from([b]); }

function encNum(n: number, p: Buffer[]): void {
  if (!Number.isInteger(n)) {
    const b = Buffer.alloc(9); b[0] = 0xcb; b.writeDoubleBE(n, 1); p.push(b); return;
  }
  if (n >= 0) {
    if (n < 0x80) { p.push(B1(n)); }
    else if (n < 0x100) { p.push(Buffer.from([0xcc, n])); }
    else if (n < 0x10000) { const b = Buffer.alloc(3); b[0] = 0xcd; b.writeUInt16BE(n, 1); p.push(b); }
    else { const b = Buffer.alloc(5); b[0] = 0xce; b.writeUInt32BE(n, 1); p.push(b); }
  } else {
    if (n >= -32) { p.push(B1(n & 0xff)); }
    else if (n >= -128) { p.push(Buffer.from([0xd0, n & 0xff])); }
    else if (n >= -32768) { const b = Buffer.alloc(3); b[0] = 0xd1; b.writeInt16BE(n, 1); p.push(b); }
    else { const b = Buffer.alloc(5); b[0] = 0xd2; b.writeInt32BE(n, 1); p.push(b); }
  }
}

function encStr(s: string, p: Buffer[]): void {
  const d = Buffer.from(s, "utf8"), len = d.length;
  if (len < 32) p.push(B1(0xa0 | len));
  else if (len < 0x100) p.push(Buffer.from([0xd9, len]));
  else if (len < 0x10000) { const b = Buffer.alloc(3); b[0] = 0xda; b.writeUInt16BE(len, 1); p.push(b); }
  else { const b = Buffer.alloc(5); b[0] = 0xdb; b.writeUInt32BE(len, 1); p.push(b); }
  p.push(d);
}

function encBin(buf: Buffer, p: Buffer[]): void {
  const len = buf.length;
  if (len < 0x100) p.push(Buffer.from([0xc4, len]));
  else if (len < 0x10000) { const b = Buffer.alloc(3); b[0] = 0xc5; b.writeUInt16BE(len, 1); p.push(b); }
  else { const b = Buffer.alloc(5); b[0] = 0xc6; b.writeUInt32BE(len, 1); p.push(b); }
  p.push(buf);
}

function encArr(arr: unknown[], p: Buffer[]): void {
  const len = arr.length;
  if (len < 16) p.push(B1(0x90 | len));
  else if (len < 0x10000) { const b = Buffer.alloc(3); b[0] = 0xdc; b.writeUInt16BE(len, 1); p.push(b); }
  else { const b = Buffer.alloc(5); b[0] = 0xdd; b.writeUInt32BE(len, 1); p.push(b); }
  for (const item of arr) enc(item, p);
}

function encMap(obj: Record<string, unknown>, p: Buffer[]): void {
  const keys = Object.keys(obj), len = keys.length;
  if (len < 16) p.push(B1(0x80 | len));
  else if (len < 0x10000) { const b = Buffer.alloc(3); b[0] = 0xde; b.writeUInt16BE(len, 1); p.push(b); }
  else { const b = Buffer.alloc(5); b[0] = 0xdf; b.writeUInt32BE(len, 1); p.push(b); }
  for (const k of keys) { encStr(k, p); enc(obj[k], p); }
}

// ── Decoder ───────────────────────────────────────────────────────────

export class DecodeError extends Error { constructor(msg: string) { super(msg); } }

/** Decode one msgpack value. Returns value + new offset. Throws DecodeError on incomplete data. */
export function decode(buf: Buffer, off = 0): { value: unknown; offset: number } {
  if (off >= buf.length) throw new DecodeError("incomplete");
  const t = buf[off]!;

  // positive fixint
  if (t < 0x80) return { value: t, offset: off + 1 };
  // fixmap
  if (t < 0x90) return decMap(buf, off + 1, t & 0x0f);
  // fixarray
  if (t < 0xa0) return decArr(buf, off + 1, t & 0x0f);
  // fixstr
  if (t < 0xc0) { const len = t & 0x1f; need(buf, off + 1, len); return { value: buf.toString("utf8", off + 1, off + 1 + len), offset: off + 1 + len }; }

  switch (t) {
    case 0xc0: return { value: null, offset: off + 1 };
    case 0xc2: return { value: false, offset: off + 1 };
    case 0xc3: return { value: true, offset: off + 1 };

    // bin8/16/32
    case 0xc4: { need(buf, off, 2); const n = buf[off + 1]!; need(buf, off + 2, n); return { value: buf.subarray(off + 2, off + 2 + n), offset: off + 2 + n }; }
    case 0xc5: { need(buf, off, 3); const n = buf.readUInt16BE(off + 1); need(buf, off + 3, n); return { value: buf.subarray(off + 3, off + 3 + n), offset: off + 3 + n }; }
    case 0xc6: { need(buf, off, 5); const n = buf.readUInt32BE(off + 1); need(buf, off + 5, n); return { value: buf.subarray(off + 5, off + 5 + n), offset: off + 5 + n }; }

    // ext8/16/32
    case 0xc7: { need(buf, off, 3); const n = buf[off + 1]!; const et = buf.readInt8(off + 2); need(buf, off + 3, n); return { value: { extType: et, data: buf.subarray(off + 3, off + 3 + n) }, offset: off + 3 + n }; }
    case 0xc8: { need(buf, off, 4); const n = buf.readUInt16BE(off + 1); const et = buf.readInt8(off + 3); need(buf, off + 4, n); return { value: { extType: et, data: buf.subarray(off + 4, off + 4 + n) }, offset: off + 4 + n }; }
    case 0xc9: { need(buf, off, 6); const n = buf.readUInt32BE(off + 1); const et = buf.readInt8(off + 5); need(buf, off + 6, n); return { value: { extType: et, data: buf.subarray(off + 6, off + 6 + n) }, offset: off + 6 + n }; }

    // float32/64
    case 0xca: need(buf, off, 5); return { value: buf.readFloatBE(off + 1), offset: off + 5 };
    case 0xcb: need(buf, off, 9); return { value: buf.readDoubleBE(off + 1), offset: off + 9 };

    // uint8/16/32
    case 0xcc: need(buf, off, 2); return { value: buf[off + 1]!, offset: off + 2 };
    case 0xcd: need(buf, off, 3); return { value: buf.readUInt16BE(off + 1), offset: off + 3 };
    case 0xce: need(buf, off, 5); return { value: buf.readUInt32BE(off + 1), offset: off + 5 };
    case 0xcf: need(buf, off, 9); return { value: Number(buf.readBigUInt64BE(off + 1)), offset: off + 9 };

    // int8/16/32
    case 0xd0: need(buf, off, 2); return { value: buf.readInt8(off + 1), offset: off + 2 };
    case 0xd1: need(buf, off, 3); return { value: buf.readInt16BE(off + 1), offset: off + 3 };
    case 0xd2: need(buf, off, 5); return { value: buf.readInt32BE(off + 1), offset: off + 5 };
    case 0xd3: need(buf, off, 9); return { value: Number(buf.readBigInt64BE(off + 1)), offset: off + 9 };

    // fixext 1/2/4/8/16
    case 0xd4: need(buf, off, 3); return { value: { extType: buf.readInt8(off + 1), data: buf.subarray(off + 2, off + 3) }, offset: off + 3 };
    case 0xd5: need(buf, off, 4); return { value: { extType: buf.readInt8(off + 1), data: buf.subarray(off + 2, off + 4) }, offset: off + 4 };
    case 0xd6: need(buf, off, 6); return { value: { extType: buf.readInt8(off + 1), data: buf.subarray(off + 2, off + 6) }, offset: off + 6 };
    case 0xd7: need(buf, off, 10); return { value: { extType: buf.readInt8(off + 1), data: buf.subarray(off + 2, off + 10) }, offset: off + 10 };
    case 0xd8: need(buf, off, 18); return { value: { extType: buf.readInt8(off + 1), data: buf.subarray(off + 2, off + 18) }, offset: off + 18 };

    // str8/16/32
    case 0xd9: { need(buf, off, 2); const n = buf[off + 1]!; need(buf, off + 2, n); return { value: buf.toString("utf8", off + 2, off + 2 + n), offset: off + 2 + n }; }
    case 0xda: { need(buf, off, 3); const n = buf.readUInt16BE(off + 1); need(buf, off + 3, n); return { value: buf.toString("utf8", off + 3, off + 3 + n), offset: off + 3 + n }; }
    case 0xdb: { need(buf, off, 5); const n = buf.readUInt32BE(off + 1); need(buf, off + 5, n); return { value: buf.toString("utf8", off + 5, off + 5 + n), offset: off + 5 + n }; }

    // array16/32
    case 0xdc: need(buf, off, 3); return decArr(buf, off + 3, buf.readUInt16BE(off + 1));
    case 0xdd: need(buf, off, 5); return decArr(buf, off + 5, buf.readUInt32BE(off + 1));

    // map16/32
    case 0xde: need(buf, off, 3); return decMap(buf, off + 3, buf.readUInt16BE(off + 1));
    case 0xdf: need(buf, off, 5); return decMap(buf, off + 5, buf.readUInt32BE(off + 1));
  }

  // negative fixint (0xe0..0xff)
  if (t >= 0xe0) return { value: t - 256, offset: off + 1 };

  throw new Error(`msgpack: unknown type 0x${t.toString(16)}`);
}

function need(buf: Buffer, off: number, n: number): void {
  if (off + n > buf.length) throw new DecodeError("incomplete");
}

function decArr(buf: Buffer, off: number, len: number): { value: unknown[]; offset: number } {
  const arr: unknown[] = [];
  for (let i = 0; i < len; i++) { const r = decode(buf, off); arr.push(r.value); off = r.offset; }
  return { value: arr, offset: off };
}

function decMap(buf: Buffer, off: number, len: number): { value: Record<string, unknown>; offset: number } {
  const map: Record<string, unknown> = {};
  for (let i = 0; i < len; i++) {
    const kr = decode(buf, off); off = kr.offset;
    const vr = decode(buf, off); off = vr.offset;
    map[String(kr.value)] = vr.value;
  }
  return { value: map, offset: off };
}
