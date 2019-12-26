let Ingress =
      { hosts : List Text
      , subdomain : Optional Text
      , ingressPorts : Optional (List Natural)
      , annotations : List { mapKey : Text, mapValue : Text }
      , requestCertificate : Bool
      }

let default =
      { hosts = [] : List Text
      , subdomain = None Text
      , ingressPorts = None (List Natural)
      , annotations = [] : List { mapKey : Text, mapValue : Text }
      , requestCertificate = False
      }

in  { Type = Ingress, default = default }
