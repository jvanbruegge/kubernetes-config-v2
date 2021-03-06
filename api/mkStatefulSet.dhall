let kube = (../packages.dhall).kubernetes

let prelude = (../packages.dhall).prelude

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
                      , matchLabels = Some (helpers.mkSelector input)
                      }
                  , template = ./internal/mkTemplate.dhall input
                  , replicas = Some input.replicas
                  }
            }

      let input2 =
              input
            ⫽ { servicePorts =
                  prelude.Optional.concat
                    (List Integer)
                    ( prelude.Optional.map
                        (List Integer)
                        (Optional (List Integer))
                        (   λ(xs : List Integer)
                          →       if prelude.List.null Integer xs

                            then  None (List Integer)

                            else  Some xs
                        )
                        input.servicePorts
                    )
              }

      in    input.extraDocuments
          # [ kube.Resource.StatefulSet set ]
          # ./internal/mkService.dhall input2
          # ./internal/mkIngress.dhall input2
