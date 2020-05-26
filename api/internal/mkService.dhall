let SimpleDeployment = ../SimpleDeployment.dhall

let kube = (../../packages.dhall).kubernetes

let prelude = (../../packages.dhall).prelude

let helpers = ./helpers.dhall

in    λ(input : SimpleDeployment.Type)
    → let ports =
            prelude.List.map
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
              (helpers.getPorts input.servicePorts input)

      let service =
                  if prelude.List.null kube.ServicePort.Type ports

            then  [] : List kube.Resource

            else  [ kube.Resource.Service
                      kube.Service::{
                      , metadata = helpers.mkMeta input
                      , spec =
                          Some
                            kube.ServiceSpec::{
                            , ports = ports
                            , selector = helpers.mkSelector input
                            , externalIPs = input.externalIPs
                            }
                      }
                  ]

      in  service
