let kube = ../kubernetes.dhall

let api = ../api.dhall

let certManagerContainer =
      kube.Container::{
      , name = "cert-manager"
      , image = Some "quay.io/jetstack/cert-manager-controller:v0.12.0"
      , args =
          [ "--v=2"
          , "--cluster-resource-namespace=\$(POD_NAMESPACE)"
          , "--leader-election-namespace=\$(POD_NAMESPACE)"
          ]
      , ports =
          [ kube.ContainerPort::{ containerPort = 9402, protocol = Some "TCP" }
          ]
      , env =
          [ kube.EnvVar::{
            , name = "POD_NAMESPACE"
            , valueFrom =
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