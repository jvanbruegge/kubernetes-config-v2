let Ingress =
      { hosts : List Text
      , ingressPorts : Optional (List Natural)
      , annotations : List { mapKey : Text, mapValue : Text }
      }

let default =
      { hosts = [] : List Text
      , ingressPorts = None (List Natural)
      , annotations = [] : List { mapKey : Text, mapValue : Text }
      }

in  { Type = Ingress, default = default }
