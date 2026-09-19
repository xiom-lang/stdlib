// p_module_path_alias.xi -- importing a moved module by its FILE PATH breaks
// the catalog when the path differs from the declared module name.
//
// `xiom/crypto/legacy/md5.xi` declares `module xiom.crypto.md5`. With
//   use xiom.crypto.legacy.md5;
// `xiom --check` reports 33 T001 errors inside xiom.crypto.rng_crypto:
//   error[T001]: catalog body [xiom.crypto.rng_crypto]:
//     cannot call 'secure_random_bytes' on this expression
// Importing the declared name (`use xiom.crypto.md5;`) is clean, and
// `use xiom.crypto.rng_crypto;` alone is clean. Same with
// `xiom.crypto.legacy.sha` (declares `xiom.crypto.sha`). The alias workaround
// (`use xiom.crypto as crypto_mod;`) does not help; full-path calls do not
// help either -- the path-based import itself corrupts `xiom.crypto`'s
// catalog identity.
//
// Path/name mismatches in the current tree (19): core/cmp, core/contracts,
// core/platform, crypto/legacy/{des,md5,sha}, crypto/{chacha,ecc,poly1305,
// rsa}, format/fmt, math/complex, num/bigfloat_agg, num/bigint, os/{env,
// path,process}, string/{char,utf8}. Several are exactly the modules the
// compiler's stdlib_api_freeze test cannot resolve ("module file deleted"),
// so one resolver fix (path import registers the DECLARED identity) likely
// fixes both gates.
module p_module_path_alias

use xiom.crypto.legacy.md5;

fn main() -> Int {
  return 0;
}
