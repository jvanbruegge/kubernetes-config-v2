let api = ../api.dhall

let settings = { namespace = "phpldapadmin" } : ./Settings.dhall

in api.mkNamespace settings.namespace
    # ./phpldapadmin-deployment.dhall settings
