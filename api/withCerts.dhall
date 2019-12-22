let kube = ../kubernetes.dhall

let Union = ../union.dhall

let SimpleDeployment = ./SimpleDeployment.dhall

let tokenPath = "/home/vault"

let certPath = "/var/certs"

let agentConfig =
      ''
      exit_after_auth = true

      auto_auth {
          method "kubernetes" {
              mount_path = "auth/kubernetes"
              config = {
                  role = "get-cert"
              }
          }

          sink "file" {
              config = {
                  path = "/home/vault/.vault-token"
              }
          }
      }
      ''

in    λ(certVolume : Text)
    → λ(input : SimpleDeployment.Type)
    → let agentConfigMapName = "vault-agent-${certVolume}-config"

      let configMap =
            kube.ConfigMap::{
            , metadata =
                kube.ObjectMeta::{
                , name = agentConfigMapName
                , namespace = Some input.namespace
                }
            , data = [ { mapKey = "agent.hcl", mapValue = agentConfig } ]
            }

      let vaultAgent =
            kube.Container::{
            , name = "vault-agent-${certVolume}"
            , image = Some "registry.hub.docker.com/library/vault:1.3.0"
            , args = [ "agent", "-config=/etc/vault/agent.hcl" ]
            , env =
                [ kube.EnvVar::{
                  , name = "VAULT_ADDR"
                  , value = Some "https://vault.vault.svc.cluster.local:8300"
                  }
                , kube.EnvVar::{
                  , name = "VAULT_SKIP_VERIFY"
                  , value = Some "true"
                  }
                ]
            , volumeMounts =
                [ kube.VolumeMount::{
                  , mountPath = "/etc/vault"
                  , name = agentConfigMapName
                  }
                ]
            }

      in    input
          ⫽ { extraDocuments =
                [ Union.ConfigMap configMap ] # input.extraDocuments
            , initContainers = [ vaultAgent ] # input.initContainers
            , volumes =
                  [ kube.Volume::{
                    , name = agentConfigMapName
                    , configMap =
                        Some
                          kube.ConfigMapVolumeSource::{
                          , name = Some agentConfigMapName
                          }
                    }
                  ]
                # input.volumes
            }
