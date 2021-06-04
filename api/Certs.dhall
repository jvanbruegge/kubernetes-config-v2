let File =
      { name : Text
      , subdir : Optional Text
      , processName : Optional Text
      , keyFileExt : Text
      , certFileExt : Text
      }

let defaultFile =
      { subdir = None Text
      , keyFileExt = "key"
      , certFileExt = "crt"
      , processName = None Text
      }

let Certs =
      { volumeName : Text
      , runAsUser : Optional Integer
      , runAsGroup : Optional Integer
      , fsGroup : Optional Integer
      , caCerts : List File
      , certs : List File
      , subdomain : Optional Text
      }

let defaultCert =
      { subdomain = None Text
      , caCerts = [] : List File
      , certs = [] : List File
      , runAsUser = None Integer
      , runAsGroup = None Integer
      , fsGroup = None Integer
      }

in  { Type = Certs
    , default = defaultCert
    , File = { Type = File, default = defaultFile }
    }
