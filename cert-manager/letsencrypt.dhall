let globalSettings = ../settings.dhall

in  { apiVersion = "cert-manager.io/v1alpha2"
    , kind = "ClusterIssuer"
    , metadata = { name = "letsencrypt-prod" }
    , spec =
        { acme =
            { email = globalSettings.userEmail
            , server = "https://acme-v02.api.letsencrypt.org/directory"
            , privateKeySecretRef =
                { name = "cerberus-systems-letsencrypt-account-key" }
            , solvers = [ { http01 = { ingress = { class = "haproxy" } } } ]
            }
        }
    }
