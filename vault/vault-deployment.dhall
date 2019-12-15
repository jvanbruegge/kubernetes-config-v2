let kube = ../kubernetes.dhall

let api = ../api.dhall

let vaultContainer =
      kube.Container::{
      , name = "vault"
      , image = Some "registry.hub.docker.com/library/vault:1.3.0"
      , env =
          [ { name = "VAULT_LOCAL_CONFIG"
            , value = Some ""
            , valueFrom = kube.EnvVarSource.default
            }
          ]
      , securityContext =
          Some
            kube.SecurityContext::{
            , capabilities =
                Some { drop = [] : List Text, add = [ "IPC_LOCK" ] }
            }
      , ports =
          [ kube.ContainerPort::{
            , containerPort = 8200
            , name = Some "vault-port"
            , protocol = Some "TCP"
            }
          ]
      }

in    λ(input : ./Settings.dhall)
    → let config =
            api.SimpleDeployment::{
            , name = "vault"
            , namespace = input.namespace
            , containers = [ vaultContainer ]
            , serviceAccount = Some input.serviceAccount
            }

      in  api.mkStatefulSet config
