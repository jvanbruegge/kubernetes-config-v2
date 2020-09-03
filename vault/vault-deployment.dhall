let kube = (../packages.dhall).kubernetes

let api = ../api.dhall

let ann = ../haproxy/annotations.dhall

let dataPath = "/vault"

let vaultPort = 8200

let internalPort = 8300

let volumeName = "vault-data"

let certName = "ca-cert-secret"

let caPath = "/etc/vault"

let vaultContainer =
      kube.Container::{
      , name = "vault"
      , image = Some "registry.hub.docker.com/library/vault:1.5.3"
      , command = Some [ "sh" ]
      , args = Some
        [ "-c"
        , ''
          mkdir -p ${dataPath}/config \
            && chown -R vault:vault ${dataPath} \
            && docker-entrypoint.sh server
          ''
        ]
      , env = Some
        [ { name = "VAULT_LOCAL_CONFIG"
          , value = Some
              ( ./vault-config.dhall
                  { path = dataPath
                  , port = vaultPort
                  , internalPort
                  , certPath = "${dataPath}/ssl"
                  , rootCaPath = "${caPath}/ca.crt"
                  , certName = None Text
                  }
              )
          , valueFrom = None kube.EnvVarSource.Type
          }
        ]
      , securityContext = Some kube.SecurityContext::{
        , capabilities = Some
          { drop = None (List Text), add = Some [ "IPC_LOCK" ] }
        }
      , ports = Some
        [ kube.ContainerPort::{
          , containerPort = vaultPort
          , name = Some "vault-port"
          , protocol = Some "TCP"
          }
        , kube.ContainerPort::{
          , containerPort = internalPort
          , name = Some "internal-port"
          , protocol = Some "TCP"
          }
        ]
      , volumeMounts = Some
        [ kube.VolumeMount::{ mountPath = dataPath, name = volumeName }
        , kube.VolumeMount::{ mountPath = caPath, name = certName }
        ]
      }

in  λ(input : ./Settings.dhall) →
      let config =
            api.SimpleDeployment::{
            , name = "vault"
            , namespace = input.namespace
            , containers = [ vaultContainer ]
            , serviceAccount = Some input.serviceAccount
            , ingress = api.Ingress::{
              , annotations = [ ann.sslPassthrough, ann.sslRedirect ]
              , ingressPorts = Some [ vaultPort ]
              }
            , volumes =
              [ kube.Volume::{
                , name = volumeName
                , persistentVolumeClaim = Some
                  { claimName = input.claimName, readOnly = None Bool }
                }
              , kube.Volume::{
                , name = certName
                , secret = Some kube.SecretVolumeSource::{
                  , secretName = Some input.certSecret
                  }
                }
              ]
            }

      in  api.mkStatefulSet config
