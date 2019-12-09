let kube = ../kubernetes.dhall

let Deployment =
      { containers : List kube.Container.Type
      , initContainers : List kube.Container.Type
      , name : Text
      , namespace : Text
      , replicas : Natural
      , serviceAccount : Optional Text
      , externalIPs : List Text
      }

let default =
      { containers = [] : List kube.Container.Type
      , initContainers = [] : List kube.Container.Type
      , replicas = 1
      , serviceAccount = None Text
      , externalIPs = [] : List Text
      }

in  { Type = Deployment, default = default }
