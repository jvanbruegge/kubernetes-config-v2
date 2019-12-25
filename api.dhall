let Ingress = ./api/Ingress.dhall

let ann = ./haproxy/annotations.dhall

in  { mkRoles = ./api/mkRoles.dhall
    , mkDeployment = ./api/mkDeployment.dhall
    , mkStatefulSet = ./api/mkStatefulSet.dhall
    , mkNamespace = ./api/mkNamespace.dhall
    , mkVolume = ./api/mkVolume.dhall
    , noIngress = Ingress::{ ingressPorts = Some ([] : List Natural) }
    , sslPassthrough =
        Ingress::{ annotations = [ ann.sslPassthrough, ann.sslRedirect ] }
    , withCerts = ./api/withCerts.dhall
    , Roles = ./api/Roles.dhall
    , SimpleDeployment = ./api/SimpleDeployment.dhall
    , Ingress = Ingress
    , Volume = ./api/Volume.dhall
    , Certs = ./api/Certs.dhall
    }
