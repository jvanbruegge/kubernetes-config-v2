let api = ../api.dhall

let kube = (../packages.dhall).kubernetes

let utils = ../utils.dhall

let helpers = ../api/internal/helpers.dhall

let settings = ../settings.dhall

let namespace = "wireguard"

let volumeName = "wireguard-data"

let claimName = "wireguard-claim"

let port = +51820

let wireguardContainer =
      kube.Container::{
      , name = "wireguard"
      , image = Some "linuxserver/wireguard:1.0.20210914"
      , ports = Some
        [ kube.ContainerPort::{ containerPort = port, protocol = Some "UDP" } ]
      , env = Some
        [ kube.EnvVar::{ name = "TZ", value = Some "Europe/Berlin" }
        , kube.EnvVar::{
          , name = "SERVERURL"
          , value = Some "wireguard.${utils.NonEmpty.head Text settings.hosts}"
          }
        , kube.EnvVar::{ name = "SERVERPORT", value = Some (Integer/show port) }
        , kube.EnvVar::{ name = "PEERS", value = Some "50" }
        , kube.EnvVar::{ name = "PEERDNS", value = Some "1.1.1.1" }
        , kube.EnvVar::{ name = "INTERNAL_SUBNET", value = Some "10.0.0.0" }
        , kube.EnvVar::{ name = "ALLOWEDIPS", value = Some "10.0.0.0/24" }
        ]
      , volumeMounts = Some
        [ kube.VolumeMount::{ mountPath = "/config", name = volumeName } ]
      , securityContext = Some kube.SecurityContext::{
        , capabilities = Some
          { drop = None (List Text), add = Some [ "NET_ADMIN", "SYS_MODULE" ] }
        }
      }

let mkDeployment =
      λ(namespace : Text) →
        let config =
              api.SimpleDeployment::{
              , name = "wireguard"
              , namespace
              , containers = [ wireguardContainer ]
              , ingress = api.noIngress
              , servicePorts = Some ([] : List Integer)
              , externalIPs = settings.serverIPs
              , securityContext = Some kube.PodSecurityContext::{
                , sysctls = Some [ { name = "net.ipv4.ip_forward", value = "1" } ]
              }
              , volumes =
                [ kube.Volume::{
                  , name = volumeName
                  , persistentVolumeClaim = Some
                    { claimName, readOnly = None Bool }
                  }
                ]
              }

        let service =
              kube.Service::{
              , metadata = helpers.mkMeta config
              , spec = Some kube.ServiceSpec::{
                , ports = Some
                  [ kube.ServicePort::{
                    , port
                    , protocol = Some "UDP"
                    , targetPort = Some (kube.IntOrString.Int port)
                    }
                  ]
                , selector = Some (helpers.mkSelector config)
                , externalIPs = Some config.externalIPs
                }
              }

        in  api.mkDeployment config # [ kube.Resource.Service service ]

in    api.mkNamespace namespace
    # api.mkVolume api.Volume::{ claimName, namespace, size = "1Gi" }
    # mkDeployment namespace
