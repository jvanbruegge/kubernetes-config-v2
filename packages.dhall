let openssl =
      https://raw.githubusercontent.com/jvanbruegge/dhall-openssl/4e638f96bcef2de7aac57b8ec4b2a12acb2f1d88/package.dhall sha256:d3bfa9880744d7abc70d4291a12681ef965b468d2412b7638e419082bc657942

let prelude =
      https://raw.githubusercontent.com/dhall-lang/dhall-lang/2eda6e2d0bd6c5bfeb243df1a80a09b2505caae4/Prelude/package.dhall sha256:46c48bba5eee7807a872bbf6c3cb6ee6c2ec9498de3543c5dcc7dd950e43999d

let kubernetes =
      https://raw.githubusercontent.com/dhall-lang/dhall-kubernetes/2ed2ffd073de6569014779284b61e4f5824de987/1.19/package.dhall sha256:6774616f7d9dd3b3fc6ebde2f2efcafabb4a1bf1a68c0671571850c1d138861f

in  { prelude, openssl, kubernetes }
