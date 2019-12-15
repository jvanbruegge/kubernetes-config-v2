let api = ../api.dhall

let settings = { namespace = "vault", serviceAccount = "vault-auth" } : ./Settings.dhall

in api.mkNamespace settings.namespace # ./roles.dhall settings
