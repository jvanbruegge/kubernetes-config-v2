let kube = (../packages.dhall).kubernetes

in    λ(name : Text)
    → [ kube.Resource.Namespace
          kube.Namespace::{ metadata = kube.ObjectMeta::{ name = Some name } }
      ]
