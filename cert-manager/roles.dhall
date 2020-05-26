let api = ../api.dhall

let kube = (../packages.dhall).kubernetes

let secrets =
      kube.PolicyRule::{
      , verbs = [ "get", "list", "watch", "create", "update", "delete" ]
      , resources = [ "secrets" ]
      , apiGroups = [ "" ]
      }

let events =
      kube.PolicyRule::{
      , verbs = [ "create", "patch" ]
      , resources = [ "events" ]
      , apiGroups = [ "" ]
      }

let mkLeaderElection =
        λ(input : ./Settings.dhall)
      → let rules =
              [ kube.PolicyRule::{
                , verbs = [ "get", "create", "update", "patch" ]
                , resources = [ "configmaps" ]
                , apiGroups = [ "" ]
                }
              ]

        in  api.mkRoles
              api.Roles::{
              , name = "cert-manager:leaderelection"
              , rules = rules
              , namespace = input.namespace
              , serviceAccount = input.serviceAccount
              }

let mkClusterRole =
        λ(name : Text)
      → λ(clusterRules : List kube.PolicyRule.Type)
      → λ(input : ./Settings.dhall)
      → api.mkRoles
          api.Roles::{
          , name = name
          , clusterRules = clusterRules
          , namespace = input.namespace
          , serviceAccount = input.serviceAccount
          , createAccount = False
          }

let mkIssuerController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = [ "issuers", "issuers/status" ]
              , apiGroups = [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = [ "issuers" ]
              , apiGroups = [ "cert-manager.io" ]
              }
            , secrets
            , events
            ]

      in  mkClusterRole "cert-manager-controller-issuers" clusterRules

let mkClusterIssuerController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = [ "clusterissuers", "clusterissuers/status" ]
              , apiGroups = [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = [ "clusterissuers" ]
              , apiGroups = [ "cert-manager.io" ]
              }
            , secrets
            , events
            ]

      in  mkClusterRole "cert-manager-controller-clusterissuers" clusterRules

let mkCertificateController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources =
                  [ "certificates"
                  , "certificates/status"
                  , "certificaterequests"
                  , "certificaterequests/status"
                  ]
              , apiGroups = [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources =
                  [ "certificates"
                  , "certificaterequests"
                  , "clusterissuers"
                  , "issuers"
                  ]
              , apiGroups = [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources =
                  [ "certificates/finalizers"
                  , "certificaterequests/finalizers"
                  ]
              , apiGroups = [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "create", "delete", "get", "list", "watch" ]
              , resources = [ "orders" ]
              , apiGroups = [ "acme.cert-manager.io" ]
              }
            , secrets
            , events
            ]

      in  mkClusterRole "cert-manager-controller-certificates" clusterRules

let mkOrdersController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = [ "orders", "orders/status" ]
              , apiGroups = [ "acme.cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = [ "orders", "challenges" ]
              , apiGroups = [ "acme.cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = [ "clusterissuers", "issuers" ]
              , apiGroups = [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "create", "delete" ]
              , resources = [ "challenges", "challenges" ]
              , apiGroups = [ "acme.cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = [ "orders/finalizers" ]
              , apiGroups = [ "acme.cert-manager.io" ]
              }
            , secrets
            , events
            ]

      in  mkClusterRole "cert-manager-controller-orders" clusterRules

let mkChallengeController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = [ "challenges", "challenges/status" ]
              , apiGroups = [ "acme.cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = [ "challenges" ]
              , apiGroups = [ "acme.cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = [ "clusterissuers", "issuers" ]
              , apiGroups = [ "cert-manager.io" ]
              }
            , secrets
            , events
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch", "create", "delete" ]
              , resources = [ "pods", "services" ]
              , apiGroups = [ "" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch", "create", "delete", "update" ]
              , resources = [ "ingresses" ]
              , apiGroups = [ "extensions" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = [ "challenges/finalizers" ]
              , apiGroups = [ "acme.cert-manager.io" ]
              }
            , secrets
            ]

      in  mkClusterRole "cert-manager-controller-challenges" clusterRules

let mkIngressShimController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "create", "update", "delete" ]
              , resources = [ "certificates", "certificaterequests" ]
              , apiGroups = [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources =
                  [ "certificates"
                  , "certificaterequests"
                  , "issuers"
                  , "clusterissuers"
                  ]
              , apiGroups = [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = [ "ingresses" ]
              , apiGroups = [ "extensions" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = [ "ingresses/finalizers" ]
              , apiGroups = [ "extensions" ]
              }
            , events
            ]

      in  mkClusterRole "cert-manager-controller-ingress-shim" clusterRules

in    λ(input : ./Settings.dhall)
    →   mkLeaderElection input
      # mkIssuerController input
      # mkClusterIssuerController input
      # mkCertificateController input
      # mkOrdersController input
      # mkChallengeController input
      # mkIngressShimController input
