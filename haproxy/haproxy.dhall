let settings =
        { namespace = "haproxy", serviceAccount = "ingress-controller" }
      : ./Settings.dhall

in    ./roles.dhall settings
    # ./default-backend.dhall settings
    # ./haproxy-deployment.dhall settings
