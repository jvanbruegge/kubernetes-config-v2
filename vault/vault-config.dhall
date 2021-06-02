let prelude = (../packages.dhall).prelude

in  λ ( i
      : { path : Text
        , port : Integer
        , internalPort : Integer
        , certPath : Text
        , rootCaPath : Text
        , certName : Optional Text
        }
      ) →
      let name = prelude.Optional.default Text "vault" i.certName

      in  ''
          ui = true
          api_addr = "https://vault.cerberus-systems.de"

          storage "file" {
            path = "${i.path}"
          }

          listener "tcp" {
            address = "0.0.0.0:${Integer/show i.port}"
            tls_key_file = "${i.certPath}/${name}.key"
            tls_cert_file = "${i.certPath}/${name}.crt"
            tls_client_ca_file = "${i.rootCaPath}"
            tls_require_and_verify_client_cert = true
          }

          listener "tcp" {
            address = "0.0.0.0:${Integer/show i.internalPort}"
            tls_key_file = "${i.certPath}/${name}.key"
            tls_cert_file = "${i.certPath}/${name}.crt"
          }
          ''
