let settings = { namespace = "haproxy", serviceAccount = "ingress-controller" }

in    ./roles.dhall settings
    # ./default-backend.dhall { namespace = settings.namespace }
