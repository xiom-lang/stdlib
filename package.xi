// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
package xiom_std {
  name: "xiom-std";
  version: "0.65.1";
  description: "XIOM standard library";
  authors: ["The XIOM Authors"];
  license: "MIT OR Apache-2.0";
  compiler = ">=0.60.0 <1.0.0";
  // R53 registry metadata (relay follow-up: package.xi needs categories +
  // stage for the next cut). Categories are the registry's controlled
  // vocabulary (max 3); stage drives the registry badge and is one of
  // incubating | stable | deprecated. xiom.std is excluded from the
  // registry's display-stage overrides, so the manifest value is the
  // operative one.
  categories: ["core", "systems", "data"];
  stage: "stable";
}
