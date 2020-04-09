let openssl =
      https://raw.githubusercontent.com/jvanbruegge/dhall-openssl/607c1cff8ba3d33a0a94da8b4d1e9bd80aa8936f/package.dhall sha256:158d452a47b08d29324d4d58ffe4030468e4cbf357482b10b5b097a694e1bb86

let prelude =
      https://raw.githubusercontent.com/dhall-lang/dhall-lang/1f2553f4cc885d01b1f37ff4c8e9eb00e80765d3/Prelude/package.dhall sha256:09d41afeee8eb9401be18ec074392898be1e778b75163f1de8a5f91424471181

let kubernetes =
      https://raw.githubusercontent.com/dhall-lang/dhall-kubernetes/4ab28225a150498aef67c226d3c5f026c95b5a1e/package.dhall sha256:2c7ac35494f16b1f39afcf3467b2f3b0ab579edb0c711cddd2c93f1cbed358bd

in  { prelude = prelude, openssl = openssl, kubernetes = kubernetes }
