let openssl =
      https://raw.githubusercontent.com/jvanbruegge/dhall-openssl/4e638f96bcef2de7aac57b8ec4b2a12acb2f1d88/package.dhall sha256:d3bfa9880744d7abc70d4291a12681ef965b468d2412b7638e419082bc657942

let prelude =
      https://raw.githubusercontent.com/dhall-lang/dhall-lang/baaac8ce151c5fc876377f784e9c32ace963a56f/Prelude/package.dhall sha256:26b0ef498663d269e4dc6a82b0ee289ec565d683ef4c00d0ebdd25333a5a3c98

let kubernetes =
      https://raw.githubusercontent.com/dhall-lang/dhall-kubernetes/master/1.19/package.dhall sha256:1ba3b2108e8f38427f649f336e21f08f20d825c91b3ac64033be8c98783345d2

in  { prelude, openssl, kubernetes }
