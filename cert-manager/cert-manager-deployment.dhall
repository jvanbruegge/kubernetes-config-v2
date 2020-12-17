let kube = (../packages.dhall).kubernetes

let api = ../api.dhall

let certManagerContainer =
      kube.Container::{
      , name = "cert-manager"
      , image = Some "quay.io/jetstack/cert-manager-controller:v1.1.0"
      , args = Some
          [ "--v=2"
          , "--cluster-resource-namespace=\$(POD_NAMESPACE)"
          , "--leader-election-namespace=\$(POD_NAMESPACE)"
          ]
      , ports = Some
          [ kube.ContainerPort::{ containerPort = 9402, protocol = Some "TCP" }
          ]
      , env = Some
          [ kube.EnvVar::{
            , name = "POD_NAMESPACE"
            , valueFrom = Some
                kube.EnvVarSource::{
                , fieldRef =
                    Some
                      kube.ObjectFieldSelector::{
                      , fieldPath = "metadata.namespace"
                      }
                }
            }
          ]
      }

in    λ(input : ./Settings.dhall)
    → let config =
            api.SimpleDeployment::{
            , name = "cert-manager"
            , namespace = input.namespace
            , serviceAccount = Some input.serviceAccount
            , containers = [ certManagerContainer ]
            , ingress = api.noIngress
            }

      in  api.mkDeployment config
