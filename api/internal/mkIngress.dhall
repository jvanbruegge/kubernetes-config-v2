let Union = ../../union.dhall

let kube = ../../kubernetes.dhall

let prelude = ../../prelude.dhall

let helpers = ./helpers.dhall

let globalSettings = ../../settings.dhall

let utils = ../../utils.dhall

let SimpleDeployment = ../SimpleDeployment.dhall

in    λ(input : SimpleDeployment.Type)
    → let ports = helpers.getPorts input.ingress.ingressPorts input

      let subdomain = prelude.Optional.default Text input.name input.ingress.subdomain

      let hosts =
                  if prelude.List.null Text input.ingress.hosts

            then  prelude.List.map
                    Text
                    Text
                    (utils.Text.prepend "${subdomain}.")
                    (utils.NonEmpty.toList Text globalSettings.hosts)

            else  input.ingress.hosts

      let mkIngressRule =
              λ(x : kube.ContainerPort.Type)
            → prelude.List.map
                Text
                kube.IngressRule.Type
                (   λ(host : Text)
                  → { host = Some host
                    , http =
                        Some
                          { paths =
                                [ { path = Some "/"
                                  , backend =
                                      { serviceName = input.name
                                      , servicePort =
                                          < Int : Natural | String : Text >.Int
                                            x.containerPort
                                      }
                                  }
                                ]
                              : List kube.HTTPIngressPath.Type
                          }
                    }
                )
                hosts

      let ingress =
                  if prelude.List.null kube.ContainerPort.Type ports

            then  [] : List Union

            else  [ Union.Ingress
                      kube.Ingress::{
                      , metadata =
                          kube.ObjectMeta::{
                          , name = input.name
                          , annotations = input.ingress.annotations
                          , namespace = Some input.namespace
                          }
                      , spec =
                          Some
                            kube.IngressSpec::{
                            , rules =
                                prelude.List.concatMap
                                  kube.ContainerPort.Type
                                  kube.IngressRule.Type
                                  mkIngressRule
                                  ports
                            }
                      }
                  ]

      in  ingress
