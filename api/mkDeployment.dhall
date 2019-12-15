let kube = ../kubernetes.dhall

let Union = ../union.dhall

let SimpleDeployment = ./SimpleDeployment.dhall

let helpers = ./internal/helpers.dhall

in    λ(input : SimpleDeployment.Type)
    → let deployment =
            kube.Deployment::{
            , metadata = helpers.mkMeta input
            , spec =
                Some
                  kube.DeploymentSpec::{
                  , selector =
                      kube.LabelSelector::{
                      , matchLabels = helpers.mkSelector input
                      }
                  , template = ./internal/mkTemplate.dhall input
                  , replicas = Some input.replicas
                  }
            }

      in  [ Union.Deployment deployment ] # ./internal/mkService.dhall input
