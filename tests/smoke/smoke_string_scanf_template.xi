module smoke_string_scanf_template
use xiom.string.scanf;
use xiom.string.template;
use xiom.io;

fn main() -> Int {
  // ---- scanf ----
  var s1 = xiom.string.scanf.str_scanf("42", "%d");
  match s1 {
    Ok(v) => { if v.len() != 1 { io.println("sc-1"); return 1; } var x0 = v[0]; if x0 != "42" { io.println("sc-2"); return 2; } };
    Err(e) => { io.println(e); return 3; };
  }
  var s2 = xiom.string.scanf.str_scanf("hello world", "%s");
  match s2 {
    Ok(v) => { if v.len() != 1 { io.println("sc-3"); return 4; } var x1 = v[0]; if x1 != "hello" { io.println("sc-4"); return 5; } };
    Err(e) => { io.println(e); return 6; };
  }
  var s3 = xiom.string.scanf.str_scanf("abc", "%d");
  match s3 {
    Ok(v) => { return 7; };
    Err(e) => {};
  }
  var s4 = xiom.string.scanf.str_scanf_ints("3 4", "%d %d");
  match s4 {
    Ok(v) => { if v.len() != 2 || v[0] != 3 || v[1] != 4 { io.println("sc-5"); return 8; } };
    Err(e) => { io.println(e); return 9; };
  }
  var s5 = xiom.string.scanf.str_scanf_ints("ff", "%x");
  match s5 {
    Ok(v) => { if v.len() != 1 || v[0] != 255 { io.println("sc-6"); return 10; } };
    Err(e) => { io.println(e); return 11; };
  }
  var s6 = xiom.string.scanf.str_scanf_ints("-17", "%d");
  match s6 {
    Ok(v) => { if v.len() != 1 || v[0] != -17 { io.println("sc-7"); return 12; } };
    Err(e) => { io.println(e); return 13; };
  }

  var s7 = xiom.string.scanf.str_scanf_floats("3.14 2.5", "%f %f");
  if !s7.is_ok { io.println(s7.remainder); return 14; }
  if s7.count != 2 { io.println("sc-8"); return 15; }
  if s7.v0 * 100.0 < 313.9 || s7.v0 * 100.0 > 314.1 { io.println("sc-9"); return 16; }
  if s7.v1 * 100.0 < 249.9 || s7.v1 * 100.0 > 250.1 { io.println("sc-10"); return 17; }
  if s7.remainder != "" { io.println("sc-11"); return 18; }
  var s8 = xiom.string.scanf.str_scanf_floats("1.5 trailing", "%f");
  if !s8.is_ok { io.println(s8.remainder); return 19; }
  if s8.count != 1 { io.println("sc-12"); return 20; }
  if s8.v0 * 100.0 < 149.9 || s8.v0 * 100.0 > 150.1 { io.println("sc-13"); return 21; }
  if s8.remainder != "" { io.println("sc-14"); return 22; }
  var s9 = xiom.string.scanf.str_scanf_floats("x", "%f");
  if s9.is_ok { io.println("sc-15"); return 23; }

  // ---- template ----
  var m = xiom.string.template.map_new();
  xiom.string.template.map_insert(&m, "name", "World");
  xiom.string.template.map_insert(&m, "n", "42");

  var t1 = xiom.string.template.template_render("Hello {{name}}!", &m);
  match t1 {
    Ok(v) => { if v != "Hello World!" { io.println("tpl-1"); return 24; } };
    Err(e) => { io.println(e); return 25; };
  }
  var t2 = xiom.string.template.template_render("{{missing}}", &m);
  match t2 {
    Ok(v) => { if v != "" { io.println("tpl-2"); return 26; } };
    Err(e) => { io.println(e); return 27; };
  }
  var t3 = xiom.string.template.template_render("{{", &m);
  match t3 {
    Ok(v) => { return 28; };
    Err(e) => {};
  }
  var t4 = xiom.string.template.template_render("x}y", &m);
  match t4 {
    Ok(v) => { return 29; };
    Err(e) => {};
  }

  var comp = xiom.string.template.template_compile("Hi {{name}}!");
  match comp {
    Ok(t) => {
      var c1 = xiom.string.template.template_render_compiled(&t, &m);
      match c1 {
        Ok(v) => { if v != "Hi World!" { io.println("tpl-3"); return 30; } };
        Err(e) => { io.println(e); return 31; };
      }
      var pl = t.placeholders;
      if pl.len() != 1 { io.println("tpl-4"); return 32; }
      var p0 = pl[0];
      if p0 != "name" { io.println("tpl-5"); return 33; }
    };
    Err(e) => { io.println(e); return 34; };
  }

  var keys = Vec[Str].new();
  keys.push("name");
  keys.push("n");
  var vals = Vec[Str].new();
  vals.push("World");
  var t5 = xiom.string.template.template_render_map("{{name}}={{n}}", &keys, &vals);
  match t5 {
    Ok(v) => { if v != "World=" { io.println("tpl-6"); return 35; } };
    Err(e) => { io.println(e); return 36; };
  }

  var t6 = xiom.string.template.template_render_fallback("{{a}}-{{b}}", &m, "?");
  match t6 {
    Ok(v) => { if v != "?-?" { io.println("tpl-7"); return 37; } };
    Err(e) => { io.println(e); return 38; };
  }

  var t7 = xiom.string.template.template_render_strict("{{missing}}", &m);
  match t7 {
    Ok(v) => { return 39; };
    Err(e) => {};
  }
  var t8 = xiom.string.template.template_render_strict("{{name}}", &m);
  match t8 {
    Ok(v) => { if v != "World" { io.println("tpl-8"); return 40; } };
    Err(e) => { io.println(e); return 41; };
  }

  var esc = xiom.string.template.template_escape("{{x}}");
  if esc != "\\{\\{x\\}\\}" { io.println("tpl-9"); return 42; }
  var t9 = xiom.string.template.template_render(esc, &m);
  match t9 {
    Ok(v) => { if v != "{{x}}" { io.println("tpl-10"); return 43; } };
    Err(e) => { io.println(e); return 44; };
  }
  if xiom.string.template.template_unescape(esc) != "{{x}}" { io.println("tpl-11"); return 45; }

  if !xiom.string.template.template_has_placeholders("{{x}}") { io.println("tpl-12"); return 46; }
  if xiom.string.template.template_has_placeholders("plain") { io.println("tpl-13"); return 47; }
  var names = xiom.string.template.template_placeholders("{{a}}-{{b}}-{{a}}");
  if names.len() != 2 { io.println("tpl-14"); return 48; }
  var n0 = names[0];
  var n1 = names[1];
  if n0 != "a" { io.println("tpl-15"); return 49; }
  if n1 != "b" { io.println("tpl-16"); return 50; }
  if xiom.string.template.template_placeholder_count("{{a}}{{b}}") != 2 { io.println("tpl-17"); return 51; }
  if xiom.string.template.template_placeholder_count("plain") != 0 { io.println("tpl-18"); return 52; }

  var v1 = xiom.string.template.template_validate("{{a}} ok");
  match v1 {
    Ok(_) => {};
    Err(e) => { io.println(e); return 53; };
  }
  var v2 = xiom.string.template.template_validate("{{");
  match v2 {
    Ok(_) => { return 54; };
    Err(e) => {};
  }
  var v3 = xiom.string.template.template_validate("a}b");
  match v3 {
    Ok(_) => { return 55; };
    Err(e) => {};
  }
  var v4 = xiom.string.template.template_validate("{{}}");
  match v4 {
    Ok(_) => { return 56; };
    Err(e) => {};
  }

  io.println("smoke_string_scanf_template: OK");
  return 0;
}
