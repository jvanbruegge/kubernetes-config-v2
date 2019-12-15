let kube = ../kubernetes.dhall

let union = ../union.dhall

let utils = ../utils.dhall

let prelude = ../prelude.dhall

let SimpleDeployment = ./SimpleDeployment.dhall

let mkTemplate =
        λ(input : SimpleDeployment.Type)
      → kube.PodTemplateSpec::{
        , metadata =
            kube.ObjectMeta::{
            , name = input.name
            , labels = [ { mapKey = "app", mapValue = input.name } ]
            }
        , spec =
            Some
              kube.PodSpec::{
              , containers = input.containers
              , initContainers = input.initContainers
              , serviceAccountName = input.serviceAccount
              }
        }

let getPorts =
        λ(input : SimpleDeployment.Type)
      → let containerPorts =
              prelude.List.concatMap
                kube.Container.Type
                kube.ContainerPort.Type
                (λ(x : kube.Container.Type) → x.ports)
                input.containers

        let filterPorts =
              prelude.Optional.default
                (List Natural)
                ( prelude.List.map
                    kube.ContainerPort.Type
                    Natural
                    (λ(x : kube.ContainerPort.Type) → x.containerPort)
                    containerPorts
                )
                input.servicePorts

        in  prelude.List.map
              kube.ContainerPort.Type
              kube.ServicePort.Type
              (   λ(x : kube.ContainerPort.Type)
                → kube.ServicePort::{
                  , port = x.containerPort
                  , name = x.name
                  , protocol = x.protocol
                  , targetPort =
                      Some
                        (< Int : Natural | String : Text >.Int x.containerPort)
                  }
              )
              ( prelude.List.filter
                  kube.ContainerPort.Type
                  (   λ(x : kube.ContainerPort.Type)
                    → utils.List.naturalElementOf x.containerPort filterPorts
                  )
                  containerPorts
              )

in    λ(input : SimpleDeployment.Type)
    → let meta =
            kube.ObjectMeta::{
            , name = input.name
            , namespace = Some input.namespace
            }

      let selector = [ { mapKey = "app", mapValue = input.name } ]

      let deployement =
            kube.Deployment::{
            , metadata = meta
            , spec =
                Some
                  kube.DeploymentSpec::{
                  , selector = kube.LabelSelector::{ matchLabels = selector }
                  , template = mkTemplate input
                  , replicas = Some input.replicas
                  }
            }

      let service =
            kube.Service::{
            , metadata = meta
            , spec =
                Some
                  kube.ServiceSpec::{
                  , ports = getPorts input
                  , selector = selector
                  , externalIPs = input.externalIPs
                  }
            }

      in  [ union.Deployment deployement, union.Service service ]
