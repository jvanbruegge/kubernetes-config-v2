let kube = (../packages.dhall).kubernetes

let prelude = (../packages.dhall).prelude

let SimpleDeployment = ./SimpleDeployment.dhall

let Certs = ./Certs.dhall

let utils = ../utils.dhall

let tokenPath = "/home/vault"

let caPath = "/home/ca"

let tokenVolume = "vault-token"

let certPath = "/var/certs"

let configPath = "/etc/vault"

let configFile = "agent.hcl"

let caVolume = "vault-agent-ca-volume"

let globalSettings = ../settings.dhall

let agentConfig =
      λ(certs : Certs.Type) →
      λ(input : SimpleDeployment.Type) →
      λ(exitAfterAuth : Bool) →
        let subdomain =
              prelude.Optional.default Text input.namespace certs.subdomain

        let hosts =
              prelude.List.map
                Text
                Text
                (λ(x : Text) → "${subdomain}.${x}")
                (   utils.NonEmpty.toList Text globalSettings.hosts
                  # [ "${input.namespace}.svc.cluster.local" ]
                )

        let cnBase = utils.NonEmpty.head Text globalSettings.hosts

        let settings =
              prelude.Text.concatSep
                " "
                ( prelude.List.map
                    Text
                    Text
                    (λ(x : Text) → "\"${x}\"")
                    [ "common_name=${subdomain}.${cnBase}"
                    , "alt_names=${prelude.Text.concatSep "," hosts}"
                    , "ttl=720h"
                    , "format=pem"
                    ]
                )

        let mkContent =
              λ(list : Bool) →
              λ(entry : Text) →
                let data =
                      if    list
                      then  ''
                            {{ range .Data.${entry} }}
                            {{ . }}
                            {{ end }}
                            ''
                      else  "{{ .Data.${entry} }}"

                in  ''
                    {{ with secret "pki_int_outside/issue/get-cert" ${settings} }}
                    ${data}
                    {{ end }}
                    ''

        let mkTemplate =
              λ(field : Text) →
              λ(list : Bool) →
              λ(cert : Bool) →
              λ(processName : Optional Text) →
              λ(path : Text) →
                ''
                template {
                    destination = "${path}"
                    error_on_missing_key = true
                    command = "${if    exitAfterAuth || list || cert == False
                                 then  ""
                                 else  prelude.Optional.default
                                         Text
                                         ""
                                         ( prelude.Optional.map
                                             Text
                                             Text
                                             ( λ(process : Text) →
                                                 "sh -c 'sleep 5; pkill -SIGHUP ${process}'"
                                             )
                                             processName
                                         )}"
                    contents = <<EOF
                ${mkContent list field}
                    EOF
                }
                ''

        let mkFieldTemplate =
              λ(field : Text) →
              λ(isList : Bool) →
              λ(cert : Bool) →
              λ(list : List Certs.File.Type) →
                prelude.Text.concatSep
                  "\n"
                  ( prelude.List.map
                      Certs.File.Type
                      Text
                      ( λ(x : Certs.File.Type) →
                          let subdir =
                                prelude.Optional.default
                                  Text
                                  ""
                                  ( prelude.Optional.map
                                      Text
                                      Text
                                      (λ(dir : Text) → "/${dir}")
                                      x.subdir
                                  )

                          let ext = if cert then x.certFileExt else x.keyFileExt

                          in  mkTemplate
                                field
                                isList
                                cert
                                x.processName
                                "${certPath}${subdir}/${x.name}.${ext}"
                      )
                      list
                  )

        in  ''
            exit_after_auth = ${if exitAfterAuth then "true" else "false"}

            auto_auth {
                method "kubernetes" {
                    mount_path = "auth/kubernetes"
                    config = {
                        role = "get-cert"
                    }
                }

                sink "file" {
                    config = {
                        path = "${tokenPath}/.vault-token"
                    }
                }
            }

            vault {
                address = "https://vault.vault.svc.cluster.local:8300"
                ca_cert = "${caPath}/ca-chain.crt"
            }

            ${mkFieldTemplate "ca_chain" True True certs.caCerts}

            ${mkFieldTemplate "certificate" False True certs.certs}

            ${mkFieldTemplate "private_key" False False certs.certs}
            ''

in  λ(certs : Certs.Type) →
    λ(input : SimpleDeployment.Type) →
      let agentConfigMapName = "vault-agent-${certs.volumeName}-config"

      let initConfigMap =
            kube.ConfigMap::{
            , metadata = kube.ObjectMeta::{
              , name = Some "${agentConfigMapName}-init"
              , namespace = Some input.namespace
              }
            , data = Some
              [ { mapKey = configFile, mapValue = agentConfig certs input True }
              ]
            }

      let sidecarConfigMap =
            kube.ConfigMap::{
            , metadata = kube.ObjectMeta::{
              , name = Some "${agentConfigMapName}-sidecar"
              , namespace = Some input.namespace
              }
            , data = Some
              [ { mapKey = configFile
                , mapValue = agentConfig certs input False
                }
              ]
            }

      let vaultAgent =
            λ(init : Bool) →
              kube.Container::{
              , name =
                  "vault-agent-${certs.volumeName}-${if    init
                                                     then  "init"
                                                     else  "sidecar"}"
              , image = Some "registry.hub.docker.com/library/vault:1.3.0"
              , args = Some
                [ "-c", "vault agent -config=${configPath}/${configFile}" ]
              , command = Some [ "sh" ]
              , volumeMounts = Some
                [ kube.VolumeMount::{
                  , mountPath = configPath
                  , name =
                      "${agentConfigMapName}-${if    init
                                               then  "init"
                                               else  "sidecar"}"
                  }
                , kube.VolumeMount::{
                  , mountPath = tokenPath
                  , name = tokenVolume
                  }
                , kube.VolumeMount::{
                  , mountPath = certPath
                  , name = certs.volumeName
                  }
                , kube.VolumeMount::{ mountPath = caPath, name = caVolume }
                ]
              }

      in    input
          ⫽ { extraDocuments =
                  [ kube.Resource.ConfigMap initConfigMap
                  , kube.Resource.ConfigMap sidecarConfigMap
                  ]
                # input.extraDocuments
            , initContainers = [ vaultAgent True ] # input.initContainers
            , containers = [ vaultAgent False ] # input.containers
            , shareProcessNamespace = Some True
            , volumes =
                  [ kube.Volume::{
                    , name = "${agentConfigMapName}-init"
                    , configMap = Some kube.ConfigMapVolumeSource::{
                      , name = Some "${agentConfigMapName}-init"
                      }
                    }
                  , kube.Volume::{
                    , name = "${agentConfigMapName}-sidecar"
                    , configMap = Some kube.ConfigMapVolumeSource::{
                      , name = Some "${agentConfigMapName}-sidecar"
                      }
                    }
                  , kube.Volume::{
                    , name = tokenVolume
                    , emptyDir = Some kube.EmptyDirVolumeSource::{
                      , medium = Some "Memory"
                      }
                    }
                  , kube.Volume::{
                    , name = certs.volumeName
                    , emptyDir = Some kube.EmptyDirVolumeSource::{
                      , medium = Some "Memory"
                      }
                    }
                  , kube.Volume::{
                    , name = caVolume
                    , configMap = Some kube.ConfigMapVolumeSource::{
                      , name = Some "ca-chain"
                      }
                    }
                  ]
                # input.volumes
            }
