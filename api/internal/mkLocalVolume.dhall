let kube = ../../kubernetes.dhall

let prelude = ../../prelude.dhall

let globalSettings = ../../settings.dhall

let utils = ../../utils.dhall

let Volume = ../Volume.dhall

in    λ(input : Volume.Type)
    → let directory = prelude.Optional.default Text input.namespace input.directory

    let name = prelude.Optional.default Text input.namespace input.name

      in  kube.PersistentVolume::{
          , metadata =
              kube.ObjectMeta::{
              , name = name
              , namespace = Some input.namespace
              }
          , spec =
              Some
                kube.PersistentVolumeSpec::{
                , capacity = [ { mapKey = "storage", mapValue = input.size } ]
                , accessModes = [ "ReadWriteOnce" ]
                , persistentVolumeReclaimPolicy = Some "Retain"
                , storageClassName = Some "local-storage"
                , local =
                    Some { path = "/data/${directory}", fsType = None Text }
                , nodeAffinity =
                    { required =
                        Some
                          { nodeSelectorTerms =
                              [ kube.NodeSelectorTerm::{
                                , matchExpressions =
                                    [ { key = "kubernetes.io/hostname"
                                      , operator = "In"
                                      , values =
                                            utils.NonEmpty.toList
                                              Text
                                              globalSettings.hosts
                                          # [ "minikube" ]
                                      }
                                    ]
                                }
                              ]
                          }
                    }
                }
          }
