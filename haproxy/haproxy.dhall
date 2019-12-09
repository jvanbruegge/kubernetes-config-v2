let api = ../api.dhall

let settings =
        { namespace = "haproxy", serviceAccount = "ingress-controller" }
      : ./Settings.dhall

in    api.mkNamespace settings.namespace
    # ./roles.dhall settings
    # ./default-backend.dhall settings
    # ./haproxy-deployment.dhall settings
