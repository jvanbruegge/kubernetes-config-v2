let kube = (../packages.dhall).kubernetes

let Volume = ./Volume.dhall

in    λ(input : Volume.Type)
    → [ kube.Resource.PersistentVolume (./internal/mkLocalVolume.dhall input)
      , kube.Resource.PersistentVolumeClaim
          (./internal/mkLocalVolumeClaim.dhall input)
      ]
