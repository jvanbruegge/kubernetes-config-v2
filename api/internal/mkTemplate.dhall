let kube = (../../packages.dhall).kubernetes

let SimpleDeployment = ../SimpleDeployment.dhall

let helpers = ./helpers.dhall

in    λ(input : SimpleDeployment.Type)
    → kube.PodTemplateSpec::{
      , metadata = Some
          kube.ObjectMeta::{
          , name = Some input.name
          , labels = Some (helpers.mkSelector input)
          }
      , spec =
          Some
            kube.PodSpec::{
            , containers = input.containers
            , initContainers = Some input.initContainers
            , serviceAccountName = input.serviceAccount
            , volumes = Some input.volumes
            , securityContext = input.securityContext
            }
      }
