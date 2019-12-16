let Volume =
      { namespace : Text
      , size : Text
      , claimName : Text
      , directory : Optional Text
      , name : Optional Text
      }

let default = { directory = None Text, name = None Text }

in  { Type = Volume, default = default }
