let kube = (../packages.dhall).kubernetes

let Ingress = ./Ingress.dhall

let Deployment =
      { containers : List kube.Container.Type
      , initContainers : List kube.Container.Type
      , name : Text
      , namespace : Text
      , replicas : Natural
      , serviceAccount : Optional Text
      , externalIPs : List Text
      , servicePorts : Optional (List Natural)
      , ingress : Ingress.Type
      , volumes : List kube.Volume.Type
      , extraDocuments : List kube.Resource
      }

let default =
      { containers = [] : List kube.Container.Type
      , initContainers = [] : List kube.Container.Type
      , replicas = 1
      , serviceAccount = None Text
      , externalIPs = [] : List Text
      , servicePorts = None (List Natural)
      , ingress = Ingress.default
      , volumes = [] : List kube.Volume.Type
      , extraDocuments = [] : List kube.Resource
      }

in  { Type = Deployment, default = default }
