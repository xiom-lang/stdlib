module smoke_string_normalize

use xiom.string.normalize;
use xiom.string.nfkc;
use xiom.string;
use xiom.io;

fn main() -> Int {
  let nfd = normalize.unicode_normalize_nfd("é");
  if string.str_len(nfd) != 3 { io.println("NFC1"); return 1; }
  let nfc = normalize.unicode_normalize_nfc("é");
  if string.str_len(nfc) != 2 { io.println("NFC2"); return 2; }
  let round = normalize.unicode_normalize_nfc(nfd);
  if round != "é" { io.println("NFC3"); return 3; }
  let nfc2 = normalize.unicode_normalize_nfc("a" + nfd);
  if nfc2 != "aé" { io.println("NFC4"); return 4; }
  let nfkc1 = nfkc.unicode_normalize_nfkc("①");
  if nfkc1 != "1" { io.println("NFC5"); return 5; }
  let nfkd1 = nfkc.unicode_normalize_nfkd("½");
  if nfkd1 != "1/2" { io.println("NFC6"); return 6; }
  let ascii = normalize.str_normalize_ascii("Café naïve");
  if ascii != "Cafe naive" { io.println("NFC7"); return 7; }
  let nfkc2 = nfkc.unicode_normalize_nfkc("ﬁ");
  if nfkc2 != "fi" { io.println("NFC8"); return 8; }
  let nfkd2 = nfkc.unicode_normalize_nfkd("⑧");
  if nfkd2 != "8" { io.println("NFC9"); return 9; }
  let nfkd3 = nfkc.unicode_normalize_nfkd("Ä");
  if string.str_len(nfkd3) != 3 { io.println("NFC10"); return 10; }
  let nfkc3 = nfkc.unicode_normalize_nfkc("Ａ");
  if nfkc3 != "A" { io.println("NFC11"); return 11; }
  io.println("OK");
  return 0;
}
