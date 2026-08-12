module smoke_string_printf_scanf_template
use xiom.string.printf;
use xiom.string.template;
use xiom.io;

fn main() -> Int {
  // ---- printf ----
  var p1 = xiom.string.printf.str_printf_i1("%d", 42);
  match p1 {
    Ok(v) => { if v != "42" { io.println("pf-1"); return 1; } };
    Err(e) => { io.println(e); return 2; };
  }
  var p2 = xiom.string.printf.str_printf_i1("%05d", 7);
  match p2 {
    Ok(v) => { if v != "00007" { io.println("pf-2"); return 3; } };
    Err(e) => { io.println(e); return 4; };
  }
  var p3 = xiom.string.printf.str_printf_i1("%x", 255);
  match p3 {
    Ok(v) => { if v != "ff" { io.println("pf-3"); return 5; } };
    Err(e) => { io.println(e); return 6; };
  }
  var p4 = xiom.string.printf.str_printf_f1("%.2f", 3.14159);
  match p4 {
    Ok(v) => { if v != "3.14" { io.println("pf-4"); return 7; } };
    Err(e) => { io.println(e); return 8; };
  }
  var p5 = xiom.string.printf.str_printf_s1("%s", "hi");
  match p5 {
    Ok(v) => { if v != "hi" { io.println("pf-5"); return 9; } };
    Err(e) => { io.println(e); return 10; };
  }
  var p6 = xiom.string.printf.str_printf_s1("%10s", "hi");
  match p6 {
    Ok(v) => { if v != "        hi" { io.println("pf-6"); return 11; } };
    Err(e) => { io.println(e); return 12; };
  }
  var p7 = xiom.string.printf.str_printf_i1("%f", 5);
  match p7 {
    Ok(v) => { return 13; };
    Err(e) => {};
  }
  var p8 = xiom.string.printf.str_printf_f1("%d", 1.5);
  match p8 {
    Ok(v) => { return 14; };
    Err(e) => {};
  }

  // ---- template ----
  var m = xiom.string.template.map_new();
  xiom.string.template.map_insert(&m, "name", "World");
  xiom.string.template.map_insert(&m, "n", "42");

  var t1 = xiom.string.template.template_render("Hello {{name}}!", &m);
  match t1 {
    Ok(v) => { if v != "Hello World!" { io.println("tpl-1"); return 15; } };
    Err(e) => { io.println(e); return 16; };
  }
  var t2 = xiom.string.template.template_render("{{missing}}", &m);
  match t2 {
    Ok(v) => { if v != "" { io.println("tpl-2"); return 17; } };
    Err(e) => { io.println(e); return 18; };
  }
  var t3 = xiom.string.template.template_render("{{", &m);
  match t3 {
    Ok(v) => { return 19; };
    Err(e) => {};
  }
  var t4 = xiom.string.template.template_render("x}y", &m);
  match t4 {
    Ok(v) => { return 20; };
    Err(e) => {};
  }

  var comp = xiom.string.template.template_compile("Hi {{name}}!");
  match comp {
    Ok(t) => {
      var c1 = xiom.string.template.template_render_compiled(&t, &m);
      match c1 {
        Ok(v) => { if v != "Hi World!" { io.println("tpl-3"); return 21; } };
        Err(e) => { io.println(e); return 22; };
      }
    };
    Err(e) => { io.println(e); return 23; };
  }

  var keys = Vec[Str].new();
  keys.push("name");
  keys.push("n");
  var vals = Vec[Str].new();
  vals.push("World");
  var t5 = xiom.string.template.template_render_map("{{name}}={{n}}", &keys, &vals);
  match t5 {
    Ok(v) => { if v != "World=" { io.println("tpl-6"); return 24; } };
    Err(e) => { io.println(e); return 25; };
  }

  var t6 = xiom.string.template.template_render_fallback("{{a}}-{{b}}", &m, "?");
  match t6 {
    Ok(v) => { if v != "?-?" { io.println("tpl-7"); return 26; } };
    Err(e) => { io.println(e); return 27; };
  }

  var t7 = xiom.string.template.template_render_strict("{{missing}}", &m);
  match t7 {
    Ok(v) => { return 28; };
    Err(e) => {};
  }
  var t8 = xiom.string.template.template_render_strict("{{name}}", &m);
  match t8 {
    Ok(v) => { if v != "World" { io.println("tpl-8"); return 29; } };
    Err(e) => { io.println(e); return 30; };
  }

  var esc = xiom.string.template.template_escape("{{x}}");
  if esc != "\\{\\{x\\}\\}" { io.println("tpl-9"); return 31; }
  var t9 = xiom.string.template.template_render(esc, &m);
  match t9 {
    Ok(v) => { if v != "{{x}}" { io.println("tpl-10"); return 32; } };
    Err(e) => { io.println(e); return 33; };
  }
  if xiom.string.template.template_unescape(esc) != "{{x}}" { io.println("tpl-11"); return 34; }

  if !xiom.string.template.template_has_placeholders("{{x}}") { io.println("tpl-12"); return 35; }
  if xiom.string.template.template_has_placeholders("plain") { io.println("tpl-13"); return 36; }

  // NOTE (compiler bug): struct-field Vec[Str] element reads miscompile, so
  // placeholder content is verified through template_placeholders, which
  // returns the Vec directly.
  var names = xiom.string.template.template_placeholders("{{a}}-{{b}}-{{a}}");
  if names.len() != 2 { io.println("tpl-14"); return 37; }
  var n0 = names[0];
  var n1 = names[1];
  if n0 != "a" { io.println("tpl-15"); return 38; }
  if n1 != "b" { io.println("tpl-16"); return 39; }
  if xiom.string.template.template_placeholder_count("{{a}}{{b}}") != 2 { io.println("tpl-17"); return 40; }
  if xiom.string.template.template_placeholder_count("plain") != 0 { io.println("tpl-18"); return 41; }

  var v1 = xiom.string.template.template_validate("{{a}} ok");
  match v1 {
    Ok(_) => {};
    Err(e) => { io.println(e); return 42; };
  }
  var v2 = xiom.string.template.template_validate("{{");
  match v2 {
    Ok(_) => { return 43; };
    Err(e) => {};
  }
  var v3 = xiom.string.template.template_validate("a}b");
  match v3 {
    Ok(_) => { return 44; };
    Err(e) => {};
  }
  var v4 = xiom.string.template.template_validate("{{}}");
  match v4 {
    Ok(_) => { return 45; };
    Err(e) => {};
  }

  io.println("smoke_string_printf_scanf_template: OK");
  return 0;
}
