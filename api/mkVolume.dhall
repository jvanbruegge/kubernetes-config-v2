let Union = ../union.dhall

let Volume = ./Volume.dhall

in    λ(input : Volume.Type)
    → [ Union.PersistentVolume (./internal/mkLocalVolume.dhall input)
      , Union.PersistentVolumeClaim (./internal/mkLocalVolumeClaim.dhall input)
      ]
