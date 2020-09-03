let kube = (../packages.dhall).kubernetes

let api = ../api.dhall

let container =
      kube.Container::{
      , name = "ingress-default-backend"
      , image = Some "gcr.io/google_containers/defaultbackend:1.0"
      , ports = Some
        [ kube.ContainerPort::{ containerPort = 8080, name = Some "http" } ]
      }

in  λ(input : ./Settings.dhall) →
      let config =
            api.SimpleDeployment::{
            , name = "ingress-default-backend"
            , namespace = input.namespace
            , replicas = 0
            , containers = [ container ]
            , ingress = api.Ingress::{
              , raw = Some kube.Ingress::{
                , metadata = kube.ObjectMeta::{
                  , name = Some "ingress-default"
                  , namespace = Some input.namespace
                  , annotations = Some
                    [ { mapKey = "ingress.kubernetes.io/config-backend"
                      , mapValue = "tcp-request content reject"
                      }
                    ]
                  }
                , spec = Some kube.IngressSpec::{
                  , backend = Some kube.IngressBackend::{
                    , serviceName = Some "ingress-default-backend"
                    , servicePort = Some (kube.IntOrString.Int 8080)
                    }
                  }
                }
              }
            }

      in  api.mkDeployment config
