// XIOM - Compression: Huffman
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.compress.huffman

// Depends on: xiom.string

// ============================================================================
// Canonical Huffman coding plus byte-level run-length encoding.
//
// Build: frequencies -> Huffman tree (canonical code assignment) -> bit-packed
// stream.  huffman_compress emits a self-describing container so
// huffman_decompress can rebuild the tree without external state:
//
//   [0..3]   original byte length (LE, masked to 32 bits)
//   [4..259] 256 code lengths (one UInt8 per byte value; 0 = unused)
//   [260..]  MSB-first packed bits (zero-padded to a byte boundary)
//
// huffman_encode / huffman_decode operate on the raw packed representation;
// huffman_compress / huffman_decompress are the one-shot container pair.
// Decode errors (truncated data, unterminated code paths) surface as Err,
// never a crash.  huffman_encode requires a tree that covers every byte in
// the input (build one with huffman_build over the same data); bytes without
// a code are skipped by the encoder.
//
// Complexity: O(n) to encode, O(n * 256) to decode via canonical scanning.
// ============================================================================

/// Huffman tree: per-symbol code lengths and canonical codes (index = byte value).
pub type HuffmanTree = {
  code_lengths: Vec[Int];
  codes: Vec[Int];
  max_len: Int;
}

/// Result of a single-symbol bit-stream walk (struct: Bool in tuples miscompiles).
type DecodeOne = {
  sym: Int;
  consumed: Int;
  ok: Bool;
}

/// Derive the canonical prefix-free codes from per-symbol code lengths.
/// Canonical order: shorter codes first, ties by symbol index. O(256).
pub fn huffman_canonical(codelengths: &Vec[Int]) -> Vec[Int] {
  var codes = Vec[Int].new();
  var max_len = 0;
  var i = 0;
  while i < 256 {
    codes.push(0);
    var v = codelengths[i];
    if v > max_len { max_len = v; };
    i = i + 1;
  }
  if max_len > 0 {
    var bl_count = Vec[Int].new();
    var m = 0;
    while m <= max_len {
      bl_count.push(0);
      m = m + 1;
    }
    var s = 0;
    while s < 256 {
      var v2 = codelengths[s];
      if v2 > 0 {
        var cnt = bl_count[v2];
        bl_count[v2] = cnt + 1;
      };
      s = s + 1;
    }
    var next_code = Vec[Int].new();
    var n2 = 0;
    while n2 <= max_len {
      next_code.push(0);
      n2 = n2 + 1;
    }
    var code = 0;
    var l2 = 1;
    while l2 <= max_len {
      var c2 = bl_count[l2 - 1];
      code = (code + c2) << 1;
      next_code[l2] = code;
      l2 = l2 + 1;
    }
    var s2 = 0;
    while s2 < 256 {
      var v3 = codelengths[s2];
      if v3 > 0 {
        var nc = next_code[v3];
        codes[s2] = nc;
        var nc2 = next_code[v3];
        next_code[v3] = nc2 + 1;
      };
      s2 = s2 + 1;
    }
  }
  return codes;
}

/// Build a HuffmanTree (lengths + canonical codes) from 256 code lengths.
fn _tree_from_lengths(lens: &Vec[Int]) -> HuffmanTree {
  var max_len = 0;
  var l = 0;
  while l < 256 {
    var v = lens[l];
    if v > max_len { max_len = v; };
    l = l + 1;
  }
  var codes = huffman_canonical(lens);
  return HuffmanTree{ code_lengths: lens; codes: codes; max_len: max_len; };
}

/// Build a Huffman tree from a 256-slot frequency table (index = byte value).
/// The tree holds per-symbol code lengths and canonical codes. Empty or
/// single-symbol inputs are handled (single symbol gets length 1).
/// Complexity: O(n^2) in the number of distinct symbols (<= 256).
pub fn huffman_build(frequencies: &Vec[Int]) -> HuffmanTree {
  var lens = Vec[Int].new();
  var i = 0;
  while i < 256 {
    lens.push(0);
    i = i + 1;
  }
  var syms = Vec[Int].new();
  var s = 0;
  while s < 256 {
    var f = frequencies[s];
    if f > 0 {
      syms.push(s);
    };
    s = s + 1;
  }
  var n_syms = syms.len();
  if n_syms == 0 {
    return _tree_from_lengths(&lens);
  };
  var weight = Vec[Int].new();
  var parent = Vec[Int].new();
  var left = Vec[Int].new();
  var right = Vec[Int].new();
  var active = Vec[Bool].new();
  var k = 0;
  while k < 512 {
    weight.push(0);
    parent.push(-1);
    left.push(0);
    right.push(0);
    active.push(false);
    k = k + 1;
  }
  var p = 0;
  while p < n_syms {
    var sym = syms[p];
    weight[sym] = frequencies[sym];
    active[sym] = true;
    p = p + 1;
  }
  var next = 256;
  var remaining = n_syms;
  while remaining > 1 {
    var min1 = -1;
    var min2 = -1;
    var idx = 0;
    while idx < next {
      var isact = active[idx];
      if isact {
        if min1 == -1 {
          min2 = min1;
          min1 = idx;
        } elif weight[idx] < weight[min1] {
          min2 = min1;
          min1 = idx;
        } elif min2 == -1 {
          min2 = idx;
        } elif weight[idx] < weight[min2] {
          min2 = idx;
        };
      };
      idx = idx + 1;
    }
    if min1 == -1 || min2 == -1 {
      break;
    };
    parent[min1] = next;
    parent[min2] = next;
    left[next] = min1;
    right[next] = min2;
    var w1 = weight[min1];
    var w2 = weight[min2];
    weight[next] = w1 + w2;
    active[min1] = false;
    active[min2] = false;
    active[next] = true;
    next = next + 1;
    remaining = remaining - 1;
  }
  var q = 0;
  while q < n_syms {
    var sym2 = syms[q];
    var node = sym2;
    var depth = 0;
    var par = parent[node];
    while par != -1 {
      depth = depth + 1;
      node = par;
      par = parent[node];
    }
    if depth == 0 {
      depth = 1;
    };
    lens[sym2] = depth;
    q = q + 1;
  }
  return _tree_from_lengths(&lens);
}

/// Extract the per-symbol code lengths as a fresh 256-slot Vec[Int].
pub fn huffman_code_lengths(tree: HuffmanTree) -> Vec[Int] {
  var result = Vec[Int].new();
  var i = 0;
  while i < 256 {
    result.push(tree.code_lengths[i]);
    i = i + 1;
  }
  return result;
}

/// Pack a flat canonical decode table: entries [0..255] are the canonical
/// codes, entries [256..511] are the matching code lengths. O(512).
pub fn huffman_table_new(codelengths: &Vec[Int]) -> Vec[Int] {
  var table = Vec[Int].new();
  var codes = huffman_canonical(codelengths);
  var i = 0;
  while i < 256 {
    table.push(codes[i]);
    i = i + 1;
  }
  var j = 0;
  while j < 256 {
    table.push(codelengths[j]);
    j = j + 1;
  }
  return table;
}

/// Return the code bits of one symbol as booleans, MSB first.
/// An uncovered symbol yields an empty Vec (documented).
pub fn huffman_encode_symbol(tree: HuffmanTree, sym: Int) -> Vec[Bool] {
  var result = Vec[Bool].new();
  if sym < 0 || sym > 255 {
    return result;
  };
  var clen = tree.code_lengths[sym];
  var code = tree.codes[sym];
  var k = clen - 1;
  while k >= 0 {
    var bit = (code >> k) & 1;
    if bit == 1 {
      result.push(true);
    } else {
      result.push(false);
    };
    k = k - 1;
  }
  return result;
}

/// Pack `data` into an MSB-first bit stream using the tree's codes.
/// O(n * avg code length). Requires the tree to cover every input byte.
pub fn huffman_encode(tree: HuffmanTree, data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var acc = 0;
  var nbits = 0;
  var len = data.len();
  var i = 0;
  while i < len {
    var b = data[i];
    var sym = b as Int;
    var clen = tree.code_lengths[sym];
    var code = tree.codes[sym];
    var k = clen - 1;
    while k >= 0 {
      acc = acc << 1;
      var bit = (code >> k) & 1;
      acc = acc | bit;
      nbits = nbits + 1;
      if nbits == 8 {
        result.push(acc as UInt8);
        acc = 0;
        nbits = 0;
      };
      k = k - 1;
    }
    i = i + 1;
  }
  if nbits > 0 {
    var shift = 8 - nbits;
    acc = acc << shift;
    result.push(acc as UInt8);
  };
  return result;
}

/// Walk one symbol out of the bit stream. Returns the decoded symbol and the
/// number of bits consumed, or ok = false when no code path closes.
fn _decode_one(tree: HuffmanTree, bits: &Vec[UInt8], byte_len: Int, bit_pos: Int) -> DecodeOne {
  var code = 0;
  var cur = 0;
  var pos = bit_pos;
  while pos < byte_len * 8 {
    var byte_index = pos / 8;
    var bit_index = pos % 8;
    var b = bits[byte_index];
    var bval = b as Int;
    var shift = 7 - bit_index;
    var bit = (bval >> shift) & 1;
    code = (code << 1) | bit;
    cur = cur + 1;
    pos = pos + 1;
    var sym = -1;
    var s = 0;
    while s < 256 {
      var clen = tree.code_lengths[s];
      if clen == cur {
        var cd = tree.codes[s];
        if cd == code {
          sym = s;
          break;
        };
      };
      s = s + 1;
    }
    if sym >= 0 {
      return DecodeOne{ sym: sym; consumed: cur; ok: true; };
    };
    if cur > tree.max_len {
      break;
    };
  }
  return DecodeOne{ sym: 0; consumed: 0; ok: false; };
}

/// Decode exactly `len` bits of the MSB-first stream back into bytes.
/// Returns Err on invalid bit patterns or stream exhaustion.
pub fn huffman_decode(tree: HuffmanTree, bits: &Vec[UInt8], len: Int) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  var byte_len = bits.len();
  var bit_pos = 0;
  while bit_pos < len {
    var one = _decode_one(tree, bits, byte_len, bit_pos);
    if !one.ok {
      return Err("huffman: invalid bit pattern in stream");
    };
    var sym = one.sym;
    var consumed = one.consumed;
    result.push(sym as UInt8);
    bit_pos = bit_pos + consumed;
    if bit_pos > len {
      return Err("huffman: code overruns declared bit length");
    };
  }
  return Ok(result);
}

/// One-shot Huffman compression: builds the frequency table and tree, packs
/// the bits, and emits the self-describing container (header documented at the
/// top of this module). Empty input yields a valid empty container.
pub fn huffman_compress(data: &Vec[UInt8]) -> Vec[UInt8] {
  var freq = Vec[Int].new();
  var i = 0;
  while i < 256 {
    freq.push(0);
    i = i + 1;
  }
  var len = data.len();
  var j = 0;
  while j < len {
    var b = data[j];
    var idx = b as Int;
    var old = freq[idx];
    freq[idx] = old + 1;
    j = j + 1;
  }
  var tree = huffman_build(&freq);
  var packed = huffman_encode(tree, data);
  var result = Vec[UInt8].new();
  result.push((len & 0xFF) as UInt8);
  result.push(((len >> 8) & 0xFF) as UInt8);
  result.push(((len >> 16) & 0xFF) as UInt8);
  result.push(((len >> 24) & 0xFF) as UInt8);
  var k = 0;
  while k < 256 {
    result.push(tree.code_lengths[k] as UInt8);
    k = k + 1;
  }
  var p = 0;
  var plen = packed.len();
  while p < plen {
    result.push(packed[p]);
    p = p + 1;
  }
  return result;
}

/// One-shot Huffman decompression of a huffman_compress container.
/// Returns Err on truncation, an invalid code table, or stream exhaustion.
// Default output ceiling for uncapped decompression (1 GiB): bounds
// decompression-bomb amplification. Capped variant accepts an explicit
// limit; see lz77.xi for the same convention.
const _HUFF_DEFAULT_CAP: Int = 1073741824;

/// Decompress Huffman-coded data; Err on malformed input.
pub fn huffman_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  return huffman_decompress_capped(data, _HUFF_DEFAULT_CAP);
}

/// Decompress with a hard ceiling on output size. The container's declared
/// length is rejected up-front when it exceeds the cap; the decode loop
/// re-checks per symbol, so a lying header cannot allocate past the cap.
pub fn huffman_decompress_capped(data: &Vec[UInt8], max_out: Int) -> Result[Vec[UInt8], Str] {
  var len = data.len();
  if len < 260 {
    return Err("huffman: container too short");
  };
  var b0 = data[0] as Int;
  var b1 = data[1] as Int;
  var b2 = data[2] as Int;
  var b3 = data[3] as Int;
  var orig_len = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
  if orig_len > max_out {
    return Err("huffman: declared output exceeds cap");
  };
  var lens = Vec[Int].new();
  var i = 0;
  while i < 256 {
    var lv = data[4 + i] as Int;
    lens.push(lv);
    i = i + 1;
  }
  var tree = _tree_from_lengths(&lens);
  var bits = Vec[UInt8].new();
  var j = 260;
  while j < len {
    bits.push(data[j]);
    j = j + 1;
  }
  var result = Vec[UInt8].new();
  var bit_pos = 0;
  var byte_len = bits.len();
  while result.len() < orig_len {
    if bit_pos >= byte_len * 8 {
      return Err("huffman: bit stream exhausted before declared length");
    };
    var one = _decode_one(tree, bits, byte_len, bit_pos);
    if !one.ok {
      return Err("huffman: invalid bit pattern in stream");
    };
    var sym = one.sym;
    var consumed = one.consumed;
    result.push(sym as UInt8);
    bit_pos = bit_pos + consumed;
  }
  return Ok(result);
}

/// Byte-level run-length encoding: [count: UInt8, byte: UInt8] pairs for runs
/// of identical bytes (count 1..255; runs longer than 255 split).
/// Complexity: O(n), n = data length.
pub fn rle_compress(data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var len = data.len();
  if len == 0 {
    return result;
  };
  var pos = 0;
  while pos < len {
    var run = 1;
    while (pos + run) < len && run < 255 {
      var a = data[pos];
      var b = data[pos + run];
      if a != b {
        break;
      };
      run = run + 1;
    }
    result.push(run as UInt8);
    result.push(data[pos]);
    pos = pos + run;
  }
  return result;
}

/// Undo byte-level run-length encoding (rle_compress format).
/// Returns Err on a truncated pair (odd trailing byte) or a zero count.
pub fn rle_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  var len = data.len();
  if len == 0 {
    return Ok(result);
  };
  if len % 2 != 0 {
    return Err("rle: odd byte count");
  };
  var pos = 0;
  while pos < len {
    var cnt = data[pos] as Int;
    pos = pos + 1;
    if cnt == 0 {
      return Err("rle: zero run count");
    };
    var val = data[pos];
    pos = pos + 1;
    var k = 0;
    while k < cnt {
      result.push(val);
      k = k + 1;
    }
  }
  return Ok(result);
}
