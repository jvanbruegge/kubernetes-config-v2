let api = ../api.dhall

let settings =
        { namespace = "vault"
        , serviceAccount = "vault-auth"
        , claimName = "vault-claim"
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
    # ./vault-deployment.dhall settings
