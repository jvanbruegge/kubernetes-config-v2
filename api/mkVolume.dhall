let kube = ../kubernetes.dhall

let Volume = ./Volume.dhall

in    λ(input : Volume.Type)
    → [ kube.Resource.PersistentVolume (./internal/mkLocalVolume.dhall input)
      , kube.Resource.PersistentVolumeClaim
          (./internal/mkLocalVolumeClaim.dhall input)
      ]
