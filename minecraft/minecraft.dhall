let api = ../api.dhall

let kube = (../packages.dhall).kubernetes

let helpers = ../api/internal/helpers.dhall

let namespace = "minecraft"

let volumeName = "minecraft-data"

let claimName = "minecraft-claim"

let port = +25565

let minecraftContainer =
      kube.Container::{
      , name = "minecraft"
      , image = Some "itzg/minecraft-server"
      , ports = Some
        [ kube.ContainerPort::{ containerPort = port, protocol = Some "TCP" } ]
      , env = Some
        [ kube.EnvVar::{ name = "EULA", value = Some "TRUE" }
        , kube.EnvVar::{ name = "VERSION", value = Some "1.18" }
        , kube.EnvVar::{ name = "MEMORY", value = Some "5G" }
        , kube.EnvVar::{ name = "ENABLE_ROLLING_LOGS", value = Some "TRUE" }
        , kube.EnvVar::{ name = "TZ", value = Some "Europe/Berlin" }
        , kube.EnvVar::{ name = "ENABLE_AUTOPAUSE", value = Some "TRUE" }
        ]
      , volumeMounts = Some
        [ kube.VolumeMount::{ mountPath = "/data", name = volumeName } ]
      }

let mkDeployment =
      λ(namespace : Text) →
        let config =
              api.SimpleDeployment::{
              , name = "minecraft"
              , namespace
              , containers = [ minecraftContainer ]
              , ingress = api.noIngress
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
                    , protocol = Some "TCP"
                    , targetPort = Some (kube.IntOrString.Int port)
                    }
                  ]
                , selector = Some (helpers.mkSelector config)
                }
              }

        in  api.mkDeployment config # [ kube.Resource.Service service ]

in    api.mkNamespace namespace
    # api.mkVolume api.Volume::{ claimName, namespace, size = "5Gi" }
    # mkDeployment namespace
