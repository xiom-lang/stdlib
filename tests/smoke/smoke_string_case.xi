module smoke_string_case
use xiom.string.case;
use xiom.string.uppercase;
use xiom.string.lowercase;
use xiom.string.titlecase;
use xiom.io;

fn main() -> Int {
  if case.str_upper("Hello") != "HELLO" { io.println("case upper"); return 1; }
  if case.str_lower("HeLLo") != "hello" { io.println("case lower"); return 2; }
  if case.str_title("hello world") != "Hello World" { io.println("case title"); return 3; }
  if case.str_swap_case("Hello") != "hELLO" { io.println("case swap_case"); return 4; }
  if case.str_capitalize("hELLO wORLD") != "Hello world" { io.println("case capitalize"); return 5; }
  if case.str_sentence_case("hello. world! bye") != "Hello. World! Bye" { io.println("case sentence"); return 6; }
  if case.str_to_camel_case("hello_world") != "helloWorld" { io.println("case camel"); return 7; }
  if case.str_to_snake_case("HelloWorld") != "hello_world" { io.println("case snake"); return 8; }
  if case.str_to_kebab_case("Hello World") != "hello-world" { io.println("case kebab"); return 9; }
  if case.str_to_pascal_case("hello world") != "HelloWorld" { io.println("case pascal"); return 10; }

  if uppercase.str_uppercase("hello") != "HELLO" { io.println("uppercase str"); return 11; }
  if uppercase.char_uppercase('a') != 'A' { io.println("uppercase char"); return 12; }
  if uppercase.char_uppercase('A') != 'A' { io.println("uppercase char noop"); return 13; }

  if lowercase.str_lowercase("HELLO") != "hello" { io.println("lowercase str"); return 14; }
  if lowercase.char_lowercase('A') != 'a' { io.println("lowercase char"); return 15; }

  if titlecase.str_titlecase("hello world") != "Hello World" { io.println("titlecase"); return 16; }
  if titlecase.str_titlecase_words("hello WORLD foo") != "Hello World Foo" { io.println("titlecase words"); return 17; }

  io.println("smoke_string_case: OK");
  return 0;
}
