let kube = (../packages.dhall).kubernetes

in  λ(name : Text) →
      [ kube.Resource.Namespace
          kube.Namespace::{ metadata = kube.ObjectMeta::{ name = Some name } }
      , kube.Resource.Secret
          kube.Secret::{
          , metadata = kube.ObjectMeta::{
            , name = Some "ca-chain"
            , namespace = Some name
            }
          , type = Some "Opaque"
          , data = Some (toMap { cert = ../ca-chain.crt as Text ? "" })
          }
      ]
