let api = ../api.dhall

let settings =
        { namespace = "cert-manager", serviceAccount = "cert-manager" }
      : ./Settings.dhall

in    api.mkNamespace settings.namespace
    # ./roles.dhall settings
    # ./cert-manager-deployment.dhall settings
