// p_wave169_xml_vectors.xi -- wave 169 lock: streaming XML tokenizer
// (xiom.serialize.xml; row 29 of docs/STDLIB-WISHLIST.md, packages sheet
// 2026-10-02: tags, quote-aware attributes, comments/PIs, entity/char-ref
// decode; tokenizer only, safe on malformed input, bounded).
// Rows (0 = all hold):
//  1 -- realistic doc tokenizes Ok with the exact kind sequence (no Eof token)
//  2 -- prolog / doctype / comment / PI payloads are the raw inner text
//  3 -- start tag: name, quote-aware attributes (double + single), self_closing
//  4 -- text entity decode, CDATA raw passthrough, end tag, self-closing flag
//  5 -- xml_decode_entities: named basics, decimal + hex char refs, UTF-8
//  6 -- malformed set: bare &, unknown entity, unterminated comment/CDATA,
//       raw '<' in attr, unquoted attr, truncated tag, bad declaration,
//       malformed end tag, empty name, lone '<' -- each a typed Err
//  7 -- error latch: after the first Err, xml_next keeps returning Err
//  8 -- streaming equivalence: tokenizer_new + xml_next matches xml_tokenize
//       and ends with XmlToken.Eof
//  9 -- bounded/iterative: 3000-deep nesting and a 20000-byte text run
// 10 -- comment rules: '-' inside ok, '--' inside rejected
// 11 -- prolog only for target "xml"; xml-stylesheet is a PI
// 12 -- duplicate attribute names survive; xml_attr_get returns the first
// 13 -- UTF-8 tag-name bytes pass through
// 14 -- char-ref validation: tab ok; > U+10FFFF, NUL, surrogate all Err
// Setup failures use 20+.

module p_wave169_xml_vectors

use xiom.serialize.xml as sxml;

fn _is_err_tokens(s: Str) -> Bool {
  let r = sxml.xml_tokenize(s);
  return r.is_err;
}

fn main() -> Int {
  let doc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE note [<!ENTITY x \"y\">]>\n<!-- header -->\n<note id=\"1\" lang='en'>\n  <to kind=\"person\">Tove &amp; Jani</to>\n  <body><![CDATA[raw <tag> & stuff]]></body>\n  <empty/>\n  <?render zoom?>\n</note>";

  // Row 1: exact token sequence.
  let tr = sxml.xml_tokenize(doc);
  if tr.is_err { return 20; }
  let ts = tr.value;
  if ts.len() != 21 { return 1; }
  if sxml.xml_token_kind(ts[0]) != "prolog" { return 1; }
  if sxml.xml_token_kind(ts[1]) != "text" { return 1; }
  if sxml.xml_token_kind(ts[2]) != "doctype" { return 1; }
  if sxml.xml_token_kind(ts[4]) != "comment" { return 1; }
  if sxml.xml_token_kind(ts[6]) != "start_tag" { return 1; }
  if sxml.xml_token_kind(ts[13]) != "cdata" { return 1; }
  if sxml.xml_token_kind(ts[16]) != "start_tag" { return 1; }
  if sxml.xml_token_kind(ts[18]) != "processing_instruction" { return 1; }
  if sxml.xml_token_kind(ts[20]) != "end_tag" { return 1; }

  // Row 2: raw payload pins.
  match ts[0] {
    Prolog(c) => {
      if c != "xml version=\"1.0\" encoding=\"UTF-8\"" { return 2; }
    },
    _ => { return 2; },
  };
  match ts[2] {
    Doctype(c) => {
      if c != " note [<!ENTITY x \"y\">]" { return 2; }
    },
    _ => { return 2; },
  };
  match ts[4] {
    Comment(c) => {
      if c != " header " { return 2; }
    },
    _ => { return 2; },
  };
  match ts[18] {
    ProcessingInstruction(c) => {
      if c != "render zoom" { return 2; }
    },
    _ => { return 2; },
  };

  // Row 3: start tag attributes.
  match ts[6] {
    StartTag(tag) => {
      if tag.name != "note" { return 3; }
      if tag.attrs.len() != 2 { return 3; }
      if tag.self_closing { return 3; }
      let a0 = sxml.xml_attr_get(&tag, "id");
      match a0 {
        Some(v) => { if v != "1" { return 3; } },
        None => { return 3; },
      };
      let a1 = sxml.xml_attr_get(&tag, "lang");
      match a1 {
        Some(v) => { if v != "en" { return 3; } },
        None => { return 3; },
      };
      let miss = sxml.xml_attr_get(&tag, "nope");
      if miss.is_some { return 3; }
      let empty = sxml.xml_attr_get(&tag, "");
      if empty.is_some { return 3; }
    },
    _ => { return 3; },
  };

  // Row 4: decoded text, raw CDATA, end tag, self-closing.
  match ts[9] {
    Text(v) => { if v != "Tove & Jani" { return 4; } },
    _ => { return 4; },
  };
  match ts[13] {
    CData(v) => { if v != "raw <tag> & stuff" { return 4; } },
    _ => { return 4; },
  };
  match ts[16] {
    StartTag(tag) => {
      if tag.name != "empty" { return 4; }
      if tag.self_closing == false { return 4; }
      if tag.attrs.len() != 0 { return 4; }
    },
    _ => { return 4; },
  };
  match ts[20] {
    EndTag(n) => { if n != "note" { return 4; } },
    _ => { return 4; },
  };

  // Row 5: standalone entity decode.
  let de = sxml.xml_decode_entities("&lt;a&gt; &quot;q&quot; &apos;x&apos; &amp;");
  if de.is_err { return 5; }
  if de.value != "<a> \"q\" 'x' &" { return 5; }
  let de2 = sxml.xml_decode_entities("&#65;&#x42;");
  if de2.is_err { return 5; }
  if de2.value != "AB" { return 5; }
  let de3 = sxml.xml_decode_entities("&#x4F60;");
  if de3.is_err { return 5; }
  if de3.value.len() != 3 { return 5; }
  if (de3.value.byte_at(0) as Int) != 0xE4 { return 5; }
  if (de3.value.byte_at(1) as Int) != 0xBD { return 5; }
  if (de3.value.byte_at(2) as Int) != 0xA0 { return 5; }
  let de4 = sxml.xml_decode_entities("");
  if de4.is_ok == false { return 5; }
  if de4.value != "" { return 5; }
  let de5 = sxml.xml_decode_entities("plain text");
  if de5.is_err { return 5; }
  if de5.value != "plain text" { return 5; }

  // Row 6: malformed set (typed Err, no crash).
  if _is_err_tokens("<a>R&D</a>") == false { return 6; }
  if _is_err_tokens("<a>&nbsp;</a>") == false { return 6; }
  if _is_err_tokens("<a><!-- x</a>") == false { return 6; }
  if _is_err_tokens("<a><![CDATA[x</a>") == false { return 6; }
  if _is_err_tokens("<a b=\"x<y\">") == false { return 6; }
  if _is_err_tokens("<a b=x>") == false { return 6; }
  if _is_err_tokens("<a") == false { return 6; }
  if _is_err_tokens("<!ENTITY x>") == false { return 6; }
  if _is_err_tokens("</a b>") == false { return 6; }
  if _is_err_tokens("<>") == false { return 6; }
  if _is_err_tokens("<") == false { return 6; }

  // Row 7: latch after the first Err.
  var tk = sxml.xml_tokenizer_new("<a & b>");
  let e1 = sxml.xml_next(&mut tk);
  if e1.is_err == false { return 7; }
  if tk.failed == false { return 7; }
  let e2 = sxml.xml_next(&mut tk);
  if e2.is_err == false { return 7; }
  let e3 = sxml.xml_next(&mut tk);
  if e3.is_err == false { return 7; }

  // Row 8: streaming equivalence on "<p>hi</p>".
  var tk2 = sxml.xml_tokenizer_new("<p>hi</p>");
  let t1 = sxml.xml_next(&mut tk2);
  if t1.is_err { return 8; }
  if sxml.xml_token_kind(t1.value) != "start_tag" { return 8; }
  let t2 = sxml.xml_next(&mut tk2);
  if t2.is_err { return 8; }
  if sxml.xml_token_kind(t2.value) != "text" { return 8; }
  let t3 = sxml.xml_next(&mut tk2);
  if t3.is_err { return 8; }
  if sxml.xml_token_kind(t3.value) != "end_tag" { return 8; }
  let t4 = sxml.xml_next(&mut tk2);
  if t4.is_err { return 8; }
  if sxml.xml_token_kind(t4.value) != "eof" { return 8; }
  let t5 = sxml.xml_next(&mut tk2);
  if t5.is_err { return 8; }
  if sxml.xml_token_kind(t5.value) != "eof" { return 8; }

  // Row 9: bounded/iterative on deep nesting and a long text run.
  var deep = "";
  var di = 0;
  while di < 3000 {
    deep = deep + "<a>";
    di = di + 1;
  };
  let dr = sxml.xml_tokenize(deep);
  if dr.is_err { return 9; }
  let dts = dr.value;
  if dts.len() != 3000 { return 9; }
  if sxml.xml_token_kind(dts[2999]) != "start_tag" { return 9; }
  var longt = "";
  var li = 0;
  while li < 20000 {
    longt = longt + "x";
    li = li + 1;
  };
  let lr = sxml.xml_tokenize(longt);
  if lr.is_err { return 9; }
  let lts = lr.value;
  if lts.len() != 1 { return 9; }
  match lts[0] {
    Text(v) => { if v.len() != 20000 { return 9; } },
    _ => { return 9; },
  };

  // Row 10: comment rules.
  let c_ok = sxml.xml_tokenize("<a><!-- a - b --></a>");
  if c_ok.is_err { return 10; }
  let cts = c_ok.value;
  match cts[1] {
    Comment(v) => { if v != " a - b " { return 10; } },
    _ => { return 10; },
  };
  let c_bad = sxml.xml_tokenize("<a><!-- a -- b --></a>");
  if c_bad.is_ok { return 10; }

  // Row 11: prolog target discrimination.
  let p1 = sxml.xml_tokenize("<?xml version=\"1.0\"?>");
  if p1.is_err { return 11; }
  let pts1 = p1.value;
  if sxml.xml_token_kind(pts1[0]) != "prolog" { return 11; }
  let p2 = sxml.xml_tokenize("<?xml-stylesheet type=\"text/xsl\" href=\"s.xsl\"?>");
  if p2.is_err { return 11; }
  let pts2 = p2.value;
  if sxml.xml_token_kind(pts2[0]) != "processing_instruction" { return 11; }

  // Row 12: duplicate attribute names (first wins in xml_attr_get).
  let d_ok = sxml.xml_tokenize("<a b=\"1\" b=\"2\">");
  if d_ok.is_err { return 12; }
  let dts = d_ok.value;
  match dts[0] {
    StartTag(tag) => {
      if tag.attrs.len() != 2 { return 12; }
      let g = sxml.xml_attr_get(&tag, "b");
      match g {
        Some(v) => { if v != "1" { return 12; } },
        None => { return 12; },
      };
    },
    _ => { return 12; },
  };

  // Row 13: UTF-8 tag-name bytes pass through unvalidated.
  let u_ok = sxml.xml_tokenize("<caf\u{00E9}/>");
  if u_ok.is_err { return 13; }
  let uts = u_ok.value;
  match uts[0] {
    StartTag(tag) => {
      if tag.name != "caf\u{00E9}" { return 13; }
      if tag.name.len() != 5 { return 13; }
      if tag.self_closing == false { return 13; }
    },
    _ => { return 13; },
  };

  // Row 14: char-ref validation.
  let r_tab = sxml.xml_decode_entities("&#9;");
  if r_tab.is_err { return 14; }
  if r_tab.value.len() != 1 { return 14; }
  let r_big = sxml.xml_decode_entities("&#x110000;");
  if r_big.is_ok { return 14; }
  let r_nul = sxml.xml_decode_entities("&#0;");
  if r_nul.is_ok { return 14; }
  let r_sur = sxml.xml_decode_entities("&#xD800;");
  if r_sur.is_ok { return 14; }
  let r_amp = sxml.xml_decode_entities("&amp;");
  if r_amp.is_err { return 14; }
  if r_amp.value != "&" { return 14; }

  return 0;
}
