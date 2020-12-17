let kube = (../../packages.dhall).kubernetes

let prelude = (../../packages.dhall).prelude

let globalSettings = ../../settings.dhall

let utils = ../../utils.dhall

let Volume = ../Volume.dhall

in    λ(input : Volume.Type)
    → let directory =
            prelude.Optional.default Text input.namespace input.directory

      let name = prelude.Optional.default Text input.namespace input.name

      in  kube.PersistentVolume::{
          , metadata =
              kube.ObjectMeta::{ name = Some name, namespace = Some input.namespace }
          , spec =
              Some
                kube.PersistentVolumeSpec::{
                , capacity = Some [ { mapKey = "storage", mapValue = input.size } ]
                , accessModes = Some [ "ReadWriteOnce" ]
                , persistentVolumeReclaimPolicy = Some "Retain"
                , storageClassName = Some "local-storage"
                , local =
                    Some { path = "/data/${directory}", fsType = None Text }
                , nodeAffinity = Some
                    { required =
                        Some
                          { nodeSelectorTerms =
                              [ kube.NodeSelectorTerm::{
                                , matchExpressions = Some
                                    [ { key = "kubernetes.io/hostname"
                                      , operator = "In"
                                      , values = Some 
                                            (utils.NonEmpty.toList
                                              Text
                                              globalSettings.hosts
                                          # [ "kube-master" ])
                                      }
                                    ]
                                }
                              ]
                          }
                    }
                }
          }
