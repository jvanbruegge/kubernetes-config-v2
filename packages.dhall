let openssl =
      https://raw.githubusercontent.com/jvanbruegge/dhall-openssl/4fbc4307c42ee1f1f34f0348522c8eeff322e17b/package.dhall sha256:6f1cd31af6093362b03aaab5d4a9a86bc44ef5b223b1aa785cd27826175baab5

let prelude =
      https://raw.githubusercontent.com/dhall-lang/dhall-lang/1f2553f4cc885d01b1f37ff4c8e9eb00e80765d3/Prelude/package.dhall sha256:09d41afeee8eb9401be18ec074392898be1e778b75163f1de8a5f91424471181

let kubernetes =
      https://raw.githubusercontent.com/dhall-lang/dhall-kubernetes/98a4e61e1cefe0ff3f2d30af75367e4a77fb0418/package.dhall sha256:7150ac4309a091740321a3a3582e7695ee4b81732ce8f1ed1691c1c52791daa1

in  { prelude = prelude, openssl = openssl, kubernetes = kubernetes }
