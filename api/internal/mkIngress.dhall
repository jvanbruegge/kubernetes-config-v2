let kube = (../../packages.dhall).kubernetes

let prelude = (../../packages.dhall).prelude

let helpers = ./helpers.dhall

let globalSettings = ../../settings.dhall

let utils = ../../utils.dhall

let SimpleDeployment = ../SimpleDeployment.dhall

in  λ(input : SimpleDeployment.Type) →
      let ports = helpers.getPorts input.ingress.ingressPorts input

      let subdomain =
            prelude.Optional.default Text input.name input.ingress.subdomain

      let hosts =
            if    prelude.List.null Text input.ingress.hosts
            then  prelude.List.map
                    Text
                    Text
                    (utils.Text.prepend "${subdomain}.")
                    (utils.NonEmpty.toList Text globalSettings.hosts)
            else  input.ingress.hosts

      let mkIngressRule =
            λ(x : kube.ContainerPort.Type) →
              prelude.List.map
                Text
                kube.IngressRule.Type
                ( λ(host : Text) →
                    { host = Some host
                    , http = Some
                      { paths =
                            [ { path = Some "/"
                              , pathType = Some "Prefix"
                              , backend = kube.IngressBackend::{
                                , serviceName = Some input.name
                                , servicePort = Some
                                    (kube.IntOrString.Int x.containerPort)
                                }
                              }
                            ]
                          : List kube.HTTPIngressPath.Type
                      }
                    }
                )
                hosts

      let tls =
            Some
              [ kube.IngressTLS::{
                , hosts = Some hosts
                , secretName =
                    if    input.ingress.requestCertificate
                    then  Some "${input.name}-letsencrypt-cert"
                    else  None Text
                }
              ]

      let certAnnotation =
            if    input.ingress.requestCertificate
            then  [ { mapKey = "cert-manager.io/cluster-issuer"
                    , mapValue = "letsencrypt-prod"
                    }
                  ]
            else  [] : List { mapKey : Text, mapValue : Text }

      let ingress =
            if    prelude.List.null kube.ContainerPort.Type ports
            then  [] : List kube.Resource
            else  [ kube.Resource.Ingress
                      kube.Ingress::{
                      , metadata = kube.ObjectMeta::{
                        , name = Some input.name
                        , annotations = Some
                            (certAnnotation # input.ingress.annotations)
                        , namespace = Some input.namespace
                        }
                      , spec = Some kube.IngressSpec::{
                        , rules = Some
                            ( prelude.List.concatMap
                                kube.ContainerPort.Type
                                kube.IngressRule.Type
                                mkIngressRule
                                ports
                            )
                        , tls
                        }
                      }
                  ]

      in  prelude.Optional.default
            (List kube.Resource)
            ingress
            (prelude.Optional.map kube.Ingress.Type (List kube.Resource) (\(x : kube.Ingress.Type) -> [ kube.Resource.Ingress x ]) input.ingress.raw)
