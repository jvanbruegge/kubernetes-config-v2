let kube = (../packages.dhall).kubernetes

let Ingress = ./Ingress.dhall

let Deployment =
      { containers : List kube.Container.Type
      , initContainers : List kube.Container.Type
      , name : Text
      , namespace : Text
      , replicas : Integer
      , serviceAccount : Optional Text
      , externalIPs : List Text
      , servicePorts : Optional (List Integer)
      , securityContext : Optional kube.PodSecurityContext.Type
      , ingress : Ingress.Type
      , volumes : List kube.Volume.Type
      , extraDocuments : List kube.Resource
      , shareProcessNamespace : Optional Bool
      }

let default =
      { containers = [] : List kube.Container.Type
      , initContainers = [] : List kube.Container.Type
      , replicas = +1
      , serviceAccount = None Text
      , externalIPs = [] : List Text
      , securityContext = None kube.PodSecurityContext.Type
      , servicePorts = None (List Integer)
      , ingress = Ingress.default
      , volumes = [] : List kube.Volume.Type
      , extraDocuments = [] : List kube.Resource
      , shareProcessNamespace = None Bool
      }

in  { Type = Deployment, default = default }
