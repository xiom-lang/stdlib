// XIOM stdlib smoke — xiom.convert.{url,uri,urn,iri}
// Returns 0 on success, nonzero on failure (process exit code).
module smoke_convert_url
use xiom.io;
use xiom.convert.url;
use xiom.convert.uri;
use xiom.convert.urn;
use xiom.convert.iri;

fn main() -> Int {
  // url: parse host/path/port
  var parsed = url.url_parse("https://example.com:8080/path?q=1");
  if !parsed.is_ok {
    io.println("smoke_convert_url: url_parse failed");
    return 1;
  }
  match parsed {
    Ok(u) => {
      if u.host != "example.com" {
        io.println("smoke_convert_url: url host failed: " + u.host);
        return 2;
      }
      if u.port != 8080 {
        io.println("smoke_convert_url: url port failed");
        return 3;
      }
      if u.path != "/path" {
        io.println("smoke_convert_url: url path failed: " + u.path);
        return 4;
      }
      if u.query != "q=1" {
        io.println("smoke_convert_url: url query failed");
        return 5;
      }
    },
    Err(e) => {
      io.println("smoke_convert_url: url_parse err: " + e);
      return 2;
    },
  }
  var bad = url.url_parse("http://");
  if bad.is_ok {
    io.println("smoke_convert_url: url_parse accepted empty host");
    return 6;
  }
  var bad2 = url.url_parse("");
  if bad2.is_ok {
    io.println("smoke_convert_url: url_parse accepted empty");
    return 6;
  }

  // url: build
  var built = url.url_build("https", "example.com", 0, "/a/b", "x=1");
  if built != "https://example.com/a/b?x=1" {
    io.println("smoke_convert_url: url_build failed: " + built);
    return 7;
  }

  // url: percent encode/decode
  var enc = url.url_encode("a b&c");
  if enc != "a%20b%26c" {
    io.println("smoke_convert_url: url_encode failed: " + enc);
    return 8;
  }
  var dec = url.url_decode("a%20b");
  if !dec.is_ok {
    io.println("smoke_convert_url: url_decode failed");
    return 9;
  }
  match dec {
    Ok(dv) => {
      if dv != "a b" {
        io.println("smoke_convert_url: url_decode value failed: " + dv);
        return 10;
      }
    },
    Err(e2) => {
      io.println("smoke_convert_url: url_decode err: " + e2);
      return 10;
    },
  }
  var decbad = url.url_decode("%zz");
  if decbad.is_ok {
    io.println("smoke_convert_url: url_decode accepted bad escape");
    return 11;
  }

  // uri: parse + normalize + resolve
  var up = uri.uri_parse("https://example.com/a/b?q=1#frag");
  if !up.is_ok {
    io.println("smoke_convert_url: uri_parse failed");
    return 12;
  }
  match up {
    Ok(uv) => {
      if uv.fragment != "frag" {
        io.println("smoke_convert_url: uri fragment failed");
        return 13;
      }
      if uv.authority != "example.com" {
        io.println("smoke_convert_url: uri authority failed");
        return 14;
      }
    },
    Err(e3) => {
      io.println("smoke_convert_url: uri_parse err: " + e3);
      return 13;
    },
  }
  var norm = uri.uri_normalize("HTTP://Example.COM/a/../b");
  if !norm.is_ok {
    io.println("smoke_convert_url: uri_normalize failed");
    return 15;
  }
  match norm {
    Ok(nv) => {
      if nv != "http://example.com/b" {
        io.println("smoke_convert_url: uri_normalize value failed: " + nv);
        return 16;
      }
    },
    Err(e4) => {
      io.println("smoke_convert_url: uri_normalize err: " + e4);
      return 16;
    },
  }
  var res = uri.uri_resolve("https://example.com/a/b/c", "../d");
  if !res.is_ok {
    io.println("smoke_convert_url: uri_resolve failed");
    return 17;
  }
  match res {
    Ok(rv) => {
      if rv != "https://example.com/a/d" {
        io.println("smoke_convert_url: uri_resolve value failed: " + rv);
        return 18;
      }
    },
    Err(e5) => {
      io.println("smoke_convert_url: uri_resolve err: " + e5);
      return 18;
    },
  }

  // urn: parse + validate + build
  var urnp = urn.urn_parse("urn:isbn:0451450523");
  if !urnp.is_ok {
    io.println("smoke_convert_url: urn_parse failed");
    return 19;
  }
  match urnp {
    Ok(t) => {
      if t.0 != "isbn" {
        io.println("smoke_convert_url: urn nid failed: " + t.0);
        return 20;
      }
      if t.1 != "0451450523" {
        io.println("smoke_convert_url: urn nss failed");
        return 21;
      }
    },
    Err(e6) => {
      io.println("smoke_convert_url: urn_parse err: " + e6);
      return 20;
    },
  }
  if !urn.urn_is_valid("urn:isbn:0451450523") {
    io.println("smoke_convert_url: urn_is_valid failed");
    return 22;
  }
  if urn.urn_is_valid("http://example.com") {
    io.println("smoke_convert_url: urn_is_valid accepted bad");
    return 23;
  }
  var ubuild = urn.urn_build("isbn", "0451450523");
  if ubuild != "urn:isbn:0451450523" {
    io.println("smoke_convert_url: urn_build failed: " + ubuild);
    return 24;
  }

  // iri: parse + to_uri
  var ip = iri.iri_parse("https://exämple.com/päth");
  if !ip.is_ok {
    io.println("smoke_convert_url: iri_parse failed");
    return 25;
  }
  var iu = iri.iri_to_uri("https://exämple.com/päth");
  if !iu.is_ok {
    io.println("smoke_convert_url: iri_to_uri failed");
    return 26;
  }
  match iu {
    Ok(uv2) => {
      if uv2 != "https://ex%C3%A4mple.com/p%C3%A4th" {
        io.println("smoke_convert_url: iri_to_uri value failed: " + uv2);
        return 27;
      }
    },
    Err(e7) => {
      io.println("smoke_convert_url: iri_to_uri err: " + e7);
      return 27;
    },
  }

  io.println("OK");
  return 0;
}
