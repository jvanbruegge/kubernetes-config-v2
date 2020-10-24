let kube = (../packages.dhall).kubernetes

in  λ(name : Text) →
      [ kube.Resource.Namespace
          kube.Namespace::{ metadata = kube.ObjectMeta::{ name = Some name } }
      , kube.Resource.ConfigMap
          kube.ConfigMap::{
          , metadata = kube.ObjectMeta::{
            , name = Some "ca-chain"
            , namespace = Some name
            }
          , data = Some
            [ { mapKey = "ca-chain.crt"
              , mapValue = ../ca-chain.crt as Text ? ""
              }
            ]
          }
      ]
