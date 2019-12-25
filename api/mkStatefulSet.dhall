let kube = ../kubernetes.dhall

let prelude = ../prelude.dhall

let SimpleDeployment = ./SimpleDeployment.dhall

let helpers = ./internal/helpers.dhall

in    λ(input : SimpleDeployment.Type)
    → let set =
            kube.StatefulSet::{
            , metadata = helpers.mkMeta input
            , spec =
                Some
                  kube.StatefulSetSpec::{
                  , serviceName = input.name
                  , selector =
                      kube.LabelSelector::{
                      , matchLabels = helpers.mkSelector input
                      }
                  , template = ./internal/mkTemplate.dhall input
                  , replicas = Some input.replicas
                  }
            }

      let input2 =
              input
            ⫽ { servicePorts =
                  prelude.Optional.concat
                    (List Natural)
                    ( prelude.Optional.map
                        (List Natural)
                        (Optional (List Natural))
                        (   λ(xs : List Natural)
                          →       if prelude.List.null Natural xs

                            then  None (List Natural)

                            else  Some xs
                        )
                        input.servicePorts
                    )
              }

      in    input.extraDocuments
          # [ kube.Resource.StatefulSet set ]
          # ./internal/mkService.dhall input2
          # ./internal/mkIngress.dhall input2
