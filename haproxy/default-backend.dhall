let kube = (../packages.dhall).kubernetes

let api = ../api.dhall

let container =
      kube.Container::{
      , name = "ingress-default-backend"
      , image = Some "gcr.io/google_containers/defaultbackend:1.0"
      , ports = Some
          [ kube.ContainerPort::{ containerPort = 8080, name = Some "http" } ]
      }

in    λ(input : ./Settings.dhall)
    → let config =
            api.SimpleDeployment::{
            , name = "ingress-default-backend"
            , namespace = input.namespace
            , containers = [ container ]
            , ingress = api.noIngress
            }

      in  api.mkDeployment config
