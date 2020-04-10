let openssl =
      https://raw.githubusercontent.com/jvanbruegge/dhall-openssl/4fbc4307c42ee1f1f34f0348522c8eeff322e17b/package.dhall sha256:6f1cd31af6093362b03aaab5d4a9a86bc44ef5b223b1aa785cd27826175baab5

let prelude =
      https://raw.githubusercontent.com/dhall-lang/dhall-lang/1f2553f4cc885d01b1f37ff4c8e9eb00e80765d3/Prelude/package.dhall sha256:09d41afeee8eb9401be18ec074392898be1e778b75163f1de8a5f91424471181

let kubernetes =
      https://raw.githubusercontent.com/dhall-lang/dhall-kubernetes/4ab28225a150498aef67c226d3c5f026c95b5a1e/package.dhall sha256:2c7ac35494f16b1f39afcf3467b2f3b0ab579edb0c711cddd2c93f1cbed358bd

in  { prelude = prelude, openssl = openssl, kubernetes = kubernetes }
