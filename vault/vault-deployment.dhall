let kube = ../kubernetes.dhall

let api = ../api.dhall

let ann = ../haproxy/annotations.dhall

let dataPath = "/vault"

let vaultPort = 8200

let volumeName = "vault-data"

let vaultContainer =
      kube.Container::{
      , name = "vault"
      , image = Some "registry.hub.docker.com/library/vault:1.3.0"
      , env =
          [ { name = "VAULT_LOCAL_CONFIG"
            , value =
                Some
                  ( ./vault-config.dhall
                      { path = dataPath
                      , port = vaultPort
                      , certPath = "${dataPath}/ssl"
                      , certName = None Text
                      }
                  )
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
            , containerPort = vaultPort
            , name = Some "vault-port"
            , protocol = Some "TCP"
            }
          ]
      , volumeMounts =
          [ kube.VolumeMount::{ mountPath = dataPath, name = volumeName } ]
      }

in    λ(input : ./Settings.dhall)
    → let config =
            api.SimpleDeployment::{
            , name = "vault"
            , namespace = input.namespace
            , containers = [ vaultContainer ]
            , serviceAccount = Some input.serviceAccount
            , ingress =
                api.Ingress::{
                , annotations = [ ann.sslPassthrough, ann.sslRedirect ]
                }
            , volumes =
                [ kube.Volume::{
                  , name = volumeName
                  , persistentVolumeClaim =
                      Some { claimName = input.claimName, readOnly = None Bool }
                  }
                ]
            }

      in  api.mkStatefulSet config
