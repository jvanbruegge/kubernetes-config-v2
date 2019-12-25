let prelude = ../../prelude.dhall

let pki_names = [ "pki_int_inside", "pki_int_outside" ]

let writePaths = [ "/issue/get-cert", "/revoke" ]

let readPaths = [ "/ca", "/ca/pem", "/ca_chain" ]

let mkPolicy =
        λ(name : Text)
      → λ(type : Text)
      → λ(path : Text)
      → ''
        path "${name}${path}" {
            capabilities = ["${type}"]
        }
        ''

let append = λ(a : Text) → λ(b : Text) → a ++ b

let mkPolicies =
        λ(name : Text)
      → let fn = mkPolicy name

        let readPolicies = prelude.List.map Text Text (fn "read") readPaths

        let writePolicies = prelude.List.map Text Text (fn "update") writePaths

        in      List/fold Text readPolicies Text append ""
            ++  List/fold Text writePolicies Text append ""

in  List/fold
      Text
      pki_names
      Text
      (λ(a : Text) → λ(b : Text) → mkPolicies a ++ b)
      ""
