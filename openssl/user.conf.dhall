let settings = ../settings.dhall

let utils = ../utils.dhall

let prelude = ../prelude.dhall

let mkAltNames =
        λ(name : Text)
      → prelude.Text.concatSep
          "\n"
          ( utils.List.indexedMap
              Text
              Text
              (   λ(i : Natural)
                → λ(x : Text)
                → "DNS.${Natural/show i} = ${name}.${x}"
              )
              (utils.NonEmpty.toList Text settings.hosts)
          )

let length =
      prelude.List.length Text (utils.NonEmpty.toList Text settings.hosts)

in    λ(name : Text)
    → ''
      [ req ]
      default_bits       = 4096
      default_md         = sha256
      prompt             = no
      encrypt_key        = no
      utf8               = yes
      distinguished_name = req_distinguished_name
      req_extensions     = v3_req

      # distinguished_name
      [ req_distinguished_name ]
      countryName            = ${settings.countryName}
      stateOrProvinceName    = ${settings.stateOrProvinceName}
      localityName           = ${settings.localityName}
      postalCode             = ${Natural/show settings.postalCode}
      streetAddress          = ${settings.streetAddress}
      organizationName       = ${settings.organizationName}
      organizationalUnitName = ${prelude.Optional.default
                                   Text
                                   "\" \""
                                   settings.organizationalUnitName}
      commonName             = ${name}.${utils.NonEmpty.head
                                           Text
                                           settings.hosts}
      emailAddress           = ${settings.emailAddress}

      [ v3_req ]
      basicConstraints = CA:FALSE
      keyUsage = nonRepudiation, digitalSignature, keyEncipherment
      subjectAltName = @alt_names

      [ alt_names ]
      ${mkAltNames name}
      DNS.${Natural/show length} = ${name}.${name}.svc.cluster.local
      ''
