let kube = (../../packages.dhall).kubernetes

let Volume = ../Volume.dhall

in    λ(input : Volume.Type)
    → kube.PersistentVolumeClaim::{
      , metadata =
          kube.ObjectMeta::{
          , name = Some input.claimName
          , namespace = Some input.namespace
          }
      , spec =
          Some
            kube.PersistentVolumeClaimSpec::{
            , accessModes = Some [ "ReadWriteOnce" ]
            , volumeMode = Some "Filesystem"
            , storageClassName = Some "local-storage"
            , resources =
                Some
                  kube.ResourceRequirements::{
                  , requests = Some [ { mapKey = "storage", mapValue = input.size } ]
                  }
            }
      }
