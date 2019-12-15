{ mkRoles = ./api/mkRoles.dhall
, mkDeployment = ./api/mkDeployment.dhall
, mkStatefulSet = ./api/mkStatefulSet.dhall
, mkNamespace = ./api/mkNamespace.dhall
, noIngress = (./api/Ingress.dhall)::{ ingressPorts = Some ([] : List Natural) }
, Roles = ./api/Roles.dhall
, SimpleDeployment = ./api/SimpleDeployment.dhall
, Ingress = ./api/Ingress.dhall
}
