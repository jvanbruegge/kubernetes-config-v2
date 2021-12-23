let globalSettings = ../settings.dhall

in  { apiVersion = "cert-manager.io/v1"
    , kind = "ClusterIssuer"
    , metadata = { name = "letsencrypt-prod" }
    , spec =
        { acme =
            { email = globalSettings.userEmail
            , server = "https://acme-v02.api.letsencrypt.org/directory"
            , preferredChain = "ISRG Root X1"
            , privateKeySecretRef =
                { name = "cerberus-systems-letsencrypt-account-key" }
            , solvers = [ { http01 = { ingress = {=} } } ]
            }
        }
    }
