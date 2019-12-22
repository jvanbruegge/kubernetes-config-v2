{ mkRoles = ./api/mkRoles.dhall
, mkDeployment = ./api/mkDeployment.dhall
, mkStatefulSet = ./api/mkStatefulSet.dhall
, mkNamespace = ./api/mkNamespace.dhall
, mkVolume = ./api/mkVolume.dhall
, noIngress = (./api/Ingress.dhall)::{ ingressPorts = Some ([] : List Natural) }
, withCerts = ./api/withCerts.dhall
, Roles = ./api/Roles.dhall
, SimpleDeployment = ./api/SimpleDeployment.dhall
, Ingress = ./api/Ingress.dhall
, Volume = ./api/Volume.dhall
}
