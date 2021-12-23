let api = ../api.dhall

let kube = (../packages.dhall).kubernetes

let namespace = "bitwarden"

let volumeName = "bitwarden-data"

let claimName = "bitwarden-claim"

let bitwardenContainer =
      kube.Container::{
      , name = "bitwarden"
      , image = Some "registry.hub.docker.com/vaultwarden/server:1.23.1-alpine"
      , ports = Some
        [ kube.ContainerPort::{ containerPort = +80, protocol = Some "TCP" } ]
      , env = Some
        [ kube.EnvVar::{ name = "WEBSOCKET_ENABLED", value = Some "true" }
        , kube.EnvVar::{ name = "SIGNUPS_ALLOWED", value = Some "false" }
        , kube.EnvVar::{ name = "DOMAIN", value = Some "https://bitwarden.cerberus-systems.de" }
        ]
      , volumeMounts = Some
        [ kube.VolumeMount::{ mountPath = "/data", name = volumeName } ]
      }

let mkDeployment =
      λ(namespace : Text) →
        let config =
              api.SimpleDeployment::{
              , name = "bitwarden"
              , namespace
              , containers = [ bitwardenContainer ]
              , ingress = api.letsencrypt
              , volumes =
                [ kube.Volume::{
                  , name = volumeName
                  , persistentVolumeClaim = Some
                    { claimName, readOnly = None Bool }
                  }
                ]
              }

        in  api.mkDeployment config

in    api.mkNamespace namespace
    # api.mkVolume api.Volume::{ claimName, namespace, size = "4Gi" }
    # mkDeployment namespace
