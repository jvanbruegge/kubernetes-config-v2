let prelude = (../packages.dhall).prelude

in    λ ( i
        : { path : Text
          , port : Natural
          , internalPort : Natural
          , certPath : Text
          , certName : Optional Text
          }
        )
    → let name = prelude.Optional.default Text "vault" i.certName

      in  ''
          ui = true
          api_addr = "https://vault.cerberus-systems.de"

          storage "file" {
            path = "${i.path}"
          }

          listener "tcp" {
            address = "0.0.0.0:${Natural/show i.port}"
            tls_key_file = "${i.certPath}/${name}.key"
            tls_cert_file = "${i.certPath}/${name}.crt"
            tls_client_ca_file = "${i.certPath}/ca.crt"
            tls_require_and_verify_client_cert = true
          }

          listener "tcp" {
            address = "0.0.0.0:${Natural/show i.internalPort}"
            tls_key_file = "${i.certPath}/${name}.key"
            tls_cert_file = "${i.certPath}/${name}.crt"
          }
          ''
