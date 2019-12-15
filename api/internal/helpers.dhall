let SimpleDeployment = ../SimpleDeployment.dhall

let kube = ../../kubernetes.dhall

let prelude = ../../prelude.dhall

let utils = ../../utils.dhall

let mkSelector =
        λ(input : SimpleDeployment.Type)
      → [ { mapKey = "app", mapValue = input.name } ]

let mkMeta =
        λ(input : SimpleDeployment.Type)
      → kube.ObjectMeta::{ name = input.name, namespace = Some input.namespace }

let getPorts =
        λ(xs : Optional (List Natural))
      → λ(input : SimpleDeployment.Type)
      → let containerPorts =
              prelude.List.concatMap
                kube.Container.Type
                kube.ContainerPort.Type
                (λ(x : kube.Container.Type) → x.ports)
                input.containers

        let filterPorts =
              prelude.Optional.default
                (List Natural)
                ( prelude.List.map
                    kube.ContainerPort.Type
                    Natural
                    (λ(x : kube.ContainerPort.Type) → x.containerPort)
                    containerPorts
                )
                xs

        in  prelude.List.filter
              kube.ContainerPort.Type
              (   λ(x : kube.ContainerPort.Type)
                → utils.List.naturalElementOf x.containerPort filterPorts
              )
              containerPorts

in  { mkMeta = mkMeta, mkSelector = mkSelector, getPorts = getPorts }
