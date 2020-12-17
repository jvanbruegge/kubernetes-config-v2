let api = ../api.dhall

let kube = (../packages.dhall).kubernetes

let settings =
        { namespace = "vault"
        , serviceAccount = "vault-auth"
        , claimName = "vault-claim"
        , certSecret = "ca-cert"
        }
      : ./Settings.dhall

in    api.mkNamespace settings.namespace
    # ./roles.dhall settings
    # api.mkVolume
        api.Volume::{
        , claimName = settings.claimName
        , namespace = settings.namespace
        , size = "1Gi"
        }
    # [ kube.Resource.Secret
          kube.Secret::{
          , metadata = kube.ObjectMeta::{
            , name = Some settings.certSecret
            , namespace = Some settings.namespace
            }
          , stringData = Some
            [ { mapKey = "ca.crt", mapValue = ../ca/ca.crt as Text } ]
          }
      ]
    # ./vault-deployment.dhall settings
