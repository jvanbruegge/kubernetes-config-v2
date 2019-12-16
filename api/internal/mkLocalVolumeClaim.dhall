let kube = ../../kubernetes.dhall

let Volume = ../Volume.dhall

in    λ(input : Volume.Type)
    → kube.PersistentVolumeClaim::{
      , metadata =
          kube.ObjectMeta::{
          , name = input.claimName
          , namespace = Some input.namespace
          }
      , spec =
          Some
            kube.PersistentVolumeClaimSpec::{
            , accessModes = [ "ReadWriteOnce" ]
            , volumeMode = Some "Filesystem"
            , storageClassName = Some "local-storage"
            , resources =
                Some
                  kube.ResourceRequirements::{
                  , requests = [ { mapKey = "storage", mapValue = input.size } ]
                  }
            }
      }
