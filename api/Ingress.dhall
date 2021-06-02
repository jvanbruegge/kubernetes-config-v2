let kube = (../packages.dhall).kubernetes

let Ingress =
      { hosts : List Text
      , subdomain : Optional Text
      , ingressPorts : Optional (List Integer)
      , annotations : List { mapKey : Text, mapValue : Text }
      , requestCertificate : Bool
      , raw : Optional kube.Ingress.Type
      }

let default =
      { hosts = [] : List Text
      , subdomain = None Text
      , ingressPorts = None (List Integer)
      , annotations = [] : List { mapKey : Text, mapValue : Text }
      , requestCertificate = False
      , raw = None kube.Ingress.Type
      }

in  { Type = Ingress, default = default }
