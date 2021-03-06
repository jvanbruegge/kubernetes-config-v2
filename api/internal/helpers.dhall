let SimpleDeployment = ../SimpleDeployment.dhall

let kube = (../../packages.dhall).kubernetes

let prelude = (../../packages.dhall).prelude

let utils = ../../utils.dhall

let mkSelector =
        λ(input : SimpleDeployment.Type)
      → [ { mapKey = "app", mapValue = input.name } ]

let mkMeta =
        λ(input : SimpleDeployment.Type)
      → kube.ObjectMeta::{ name = Some input.name, namespace = Some input.namespace }

let ContainerPort = kube.ContainerPort.Type

let getPorts =
        λ(xs : Optional (List Integer))
      → λ(input : SimpleDeployment.Type)
      → let containerPorts =
              prelude.List.concatMap
                kube.Container.Type
                ContainerPort
                (   λ(x : kube.Container.Type)
                  → prelude.List.concat
                      ContainerPort
                      (prelude.Optional.toList (List ContainerPort) x.ports)
                )
                input.containers

        let filterPorts =
              prelude.Optional.default
                (List Integer)
                ( prelude.List.map
                    kube.ContainerPort.Type
                    Integer
                    (λ(x : kube.ContainerPort.Type) → x.containerPort)
                    containerPorts
                )
                ( prelude.Optional.fold
                    (List Integer)
                    xs
                    (Optional (List Integer))
                    (λ(x : List Integer) → Some x)
                    input.servicePorts
                )

        in  prelude.List.filter
              kube.ContainerPort.Type
              (   λ(x : kube.ContainerPort.Type)
                → utils.List.integerElementOf x.containerPort filterPorts
              )
              containerPorts

in  { mkMeta = mkMeta, mkSelector = mkSelector, getPorts = getPorts }
