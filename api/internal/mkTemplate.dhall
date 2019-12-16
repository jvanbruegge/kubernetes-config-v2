let kube = ../../kubernetes.dhall

let SimpleDeployment = ../SimpleDeployment.dhall

let helpers = ./helpers.dhall

in    λ(input : SimpleDeployment.Type)
    → kube.PodTemplateSpec::{
      , metadata =
          kube.ObjectMeta::{
          , name = input.name
          , labels = helpers.mkSelector input
          }
      , spec =
          Some
            kube.PodSpec::{
            , containers = input.containers
            , initContainers = input.initContainers
            , serviceAccountName = input.serviceAccount
            , volumes = input.volumes
            }
      }
