let kube = (../packages.dhall).kubernetes

let prelude = (../packages.dhall).prelude

let SimpleDeployment = ./SimpleDeployment.dhall

let Certs = ./Certs.dhall

let utils = ../utils.dhall

let tokenPath = "/home/vault"

let tokenVolume = "vault-token"

let certPath = "/var/certs"

let configPath = "/etc/vault"

let configFile = "agent.hcl"

let globalSettings = ../settings.dhall

let agentConfig =
        λ(certs : Certs.Type)
      → λ(input : SimpleDeployment.Type)
      → let subdomain =
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
                λ(list : Bool)
              → λ(entry : Text)
              → let data =
                            if list

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
                λ(field : Text)
              → λ(list : Bool)
              → λ(path : Text)
              → ''
                template {
                    destination = "${path}"
                    error_on_missing_key = true
                    contents = <<EOF
                ${mkContent list field}
                    EOF
                }
                ''

        let mkFieldTemplate =
                λ(field : Text)
              → λ(isList : Bool)
              → λ(cert : Bool)
              → λ(list : List Certs.File.Type)
              → prelude.Text.concatSep
                  "\n"
                  ( prelude.List.map
                      Certs.File.Type
                      Text
                      (   λ(x : Certs.File.Type)
                        → let subdir =
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
                                "${certPath}${subdir}/${x.name}.${ext}"
                      )
                      list
                  )

        in  ''
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
                        path = "${tokenPath}/.vault-token"
                    }
                }
            }

            vault {
                address = "https://vault.vault.svc.cluster.local:8300"
                tls_skip_verify = true
            }

            ${mkFieldTemplate "ca_chain" True True certs.caCerts}

            ${mkFieldTemplate "certificate" False True certs.certs}

            ${mkFieldTemplate "private_key" False False certs.certs}
            ''

in    λ(certs : Certs.Type)
    → λ(input : SimpleDeployment.Type)
    → let agentConfigMapName = "vault-agent-${certs.volumeName}-config"

      let configMap =
            kube.ConfigMap::{
            , metadata =
                kube.ObjectMeta::{
                , name = Some agentConfigMapName
                , namespace = Some input.namespace
                }
            , data = Some
                [ { mapKey = configFile, mapValue = agentConfig certs input } ]
            }

      let vaultAgent =
            kube.Container::{
            , name = "vault-agent-${certs.volumeName}"
            , image = Some "registry.hub.docker.com/library/vault:1.3.0"
            , args = Some [ "agent", "-config=${configPath}/${configFile}" ]
            , volumeMounts = Some
                [ kube.VolumeMount::{
                  , mountPath = configPath
                  , name = agentConfigMapName
                  }
                , kube.VolumeMount::{
                  , mountPath = tokenPath
                  , name = tokenVolume
                  }
                , kube.VolumeMount::{
                  , mountPath = certPath
                  , name = certs.volumeName
                  }
                ]
            }

      in    input
          ⫽ { extraDocuments =
                [ kube.Resource.ConfigMap configMap ] # input.extraDocuments
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
                  , kube.Volume::{
                    , name = tokenVolume
                    , emptyDir = Some
                        kube.EmptyDirVolumeSource::{ medium = Some "Memory" }
                    }
                  , kube.Volume::{
                    , name = certs.volumeName
                    , emptyDir = Some
                        kube.EmptyDirVolumeSource::{ medium = Some "Memory" }
                    }
                  ]
                # input.volumes
            }
