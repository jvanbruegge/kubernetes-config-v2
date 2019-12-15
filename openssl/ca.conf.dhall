let prelude = ../prelude.dhall

let settings = ../settings.dhall

let utils = ../utils.dhall

let hostList = utils.NonEmpty.toList Text settings.hosts

let mkConstraints =
        λ(type : Text)
      → prelude.Text.concatSep
          "\n"
          ( utils.List.indexedMap
              Text
              Text
              (   λ(n : Natural)
                → λ(s : Text)
                → "permitted;${type}.${Natural/show n} = ${s}"
              )
              hostList
          )

in    λ(directory : Text)
    → ''
      CA_HOME                 = .

      [ ca ]
      default_ca              = root_ca

      [ root_ca ]
      dir                     = ${directory}
      certificate             = $dir/ca.crt
      private_key             = $dir/ca.key
      new_certs_dir           = $dir
      database                = $dir/ca.index
      serial                  = $dir/ca.serial
      default_days            = ${Natural/show settings.caValidDays}
      default_md              = sha256
      email_in_dn             = no
      policy                  = policy
      unique_subject          = no

      # Distinguished Name Policy for CAs
      [ policy ]
      countryName             = optional
      stateOrProvinceName     = optional
      localityName            = optional
      organizationName        = supplied
      organizationalUnitName  = optional
      commonName              = supplied

      [ root-ca_req_ext ]
      subjectKeyIdentifier    = hash
      subjectAltName          = @subject_alt_name
      authorityKeyIdentifier = keyid:always,issuer
      basicConstraints = critical, CA:true
      keyUsage = critical, digitalSignature, cRLSign, keyCertSign

      [ req ]
      default_bits            = 4096
      default_keyfile         = generated/ca.key
      encrypt_key             = yes
      default_md              = sha256
      string_mask             = utf8only
      utf8                    = yes
      prompt                  = no
      req_extensions          = root-ca_req_ext
      distinguished_name      = distinguished_name
      subjectAltName          = @subject_alt_name

      [ root-ca_ext ]
      basicConstraints        = critical, CA:true
      keyUsage                = critical, keyCertSign
      subjectKeyIdentifier    = hash
      subjectAltName          = @subject_alt_name
      authorityKeyIdentifier  = keyid:always
      issuerAltName           = issuer:copy
      authorityInfoAccess     = @auth_info_access

      [ distinguished_name ]
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
      commonName             = ${settings.commonName}
      emailAddress           = ${settings.emailAddress}

      [ intermediate-ca_ext ]
      basicConstraints        = critical, CA:true, pathlen:0
      keyUsage                = critical, keyCertSign
      nameConstraints         = critical, @name_constraints
      subjectKeyIdentifier    = hash
      subjectAltName          = @subject_alt_name
      authorityKeyIdentifier  = keyid:always
      issuerAltName           = issuer:copy
      authorityInfoAccess     = @auth_info_access

      [ subject_alt_name ]
      URI                     = ${utils.NonEmpty.head Text settings.hosts}
      email                   = ${settings.emailAddress}

      [ name_constraints ]
      ${mkConstraints "DNS"}
      permitted;DNS.${Natural/show
                        (prelude.List.length Text hostList)} = svc.cluster.local
      ${mkConstraints "email"}

      [ auth_info_access ]
      caIssuers;URI           = ${settings.authInfoAccess}
      ''
