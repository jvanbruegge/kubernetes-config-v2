let api = ../api.dhall

let kube = (../packages.dhall).kubernetes

let clusterRules =
      [ kube.PolicyRule::{
        , verbs = [ "list", "watch" ]
        , resources = Some
          [ "configmaps", "endpoints", "nodes", "pods", "secrets" ]
        , apiGroups = Some [ "" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "get" ]
        , resources = Some [ "nodes" ]
        , apiGroups = Some [ "" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "get", "list", "watch" ]
        , resources = Some [ "services" ]
        , apiGroups = Some [ "" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "create", "patch" ]
        , resources = Some [ "events" ]
        , apiGroups = Some [ "" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "get", "list", "watch" ]
        , resources = Some [ "ingresses", "ingressclasses" ]
        , apiGroups = Some [ "extensions", "networking.k8s.io" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "update" ]
        , resources = Some [ "ingresses/status" ]
        , apiGroups = Some [ "extensions", "networking.k8s.io" ]
        }
      ]

let rules =
      [ kube.PolicyRule::{
        , verbs = [ "get" ]
        , resources = Some [ "configmaps", "pods", "secrets", "namespaces" ]
        , apiGroups = Some [ "" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "get", "update", "create" ]
        , resources = Some [ "configmaps", "endpoints" ]
        , apiGroups = Some [ "" ]
        }
      ]

in  λ(input : ./Settings.dhall) →
      api.mkRoles
        api.Roles::{
        , name = input.serviceAccount
        , clusterRules
        , rules
        , namespace = input.namespace
        , serviceAccount = input.serviceAccount
        }
