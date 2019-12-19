let api = ../api.dhall

let settings =
      { namespace = "ldap", claimName = "ldap-claim" } : ./Settings.dhall

in    api.mkNamespace settings.namespace
    # api.mkVolume
        api.Volume::{
        , claimName = settings.claimName
        , namespace = settings.namespace
        , size = "1Gi"
        }
    # ./ldap-deployment.dhall settings
