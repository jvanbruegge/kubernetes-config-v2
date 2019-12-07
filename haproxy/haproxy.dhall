let settings = {
    namespace = "haproxy",
    serviceAccount = "ingress-controller"
}

in ./roles.dhall settings
