let File =
      { name : Text
      , subdir : Optional Text
      , keyFileExt : Text
      , certFileExt : Text
      }

let defaultFile =
      { subdir = None Text, keyFileExt = "key", certFileExt = "crt" }

let Certs =
      { volumeName : Text
      , caCerts : List File
      , certs : List File
      , subdomain : Optional Text
      }

let defaultCert =
      { subdomain = None Text
      , caCerts = [] : List File
      , certs = [] : List File
      }

in  { Type = Certs
    , default = defaultCert
    , File = { Type = File, default = defaultFile }
    }
