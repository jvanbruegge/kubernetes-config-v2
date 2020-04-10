let openssl = (../packages.dhall).openssl

let settings = ../settings.dhall

let Cert =
      { Type =
          { cn : Text
          , o : Optional Text
          , altNames : List Text
          , altIPs : List Text
          }
      , default =
          { o = None Text, altNames = [] : List Text, altIPs = [] : List Text }
      }

let mkKubernetesCert =
        λ(args : Cert.Type)
      → openssl.mkConfig
          openssl.Config::{
          , distinguishedName = openssl.DistinguishedName::{
            , commonName = args.cn
            , organization = args.o
            }
          , altNames = args.altNames
          , altIPs = args.altIPs
          , usage =
            [ openssl.KeyUsage.DigitalSignature
            , openssl.KeyUsage.KeyEncipherment
            , openssl.KeyUsage.ServerAuth
            , openssl.KeyUsage.ClientAuth
            ]
          }

let adminCert =
      mkKubernetesCert Cert::{ cn = "admin", o = Some "system:masters" }

let kubletCert =
      mkKubernetesCert
        Cert::{
        , cn = "system:node:master"
        , o = Some "system:nodes"
        , altIPs = settings.serverIPs
        }

let kubeControllerManagerCert =
      mkKubernetesCert
        Cert::{
        , cn = "system:kube-controller-manager"
        , o = Some "system:kube-controller-manager"
        }

let kubeProxyCert =
      mkKubernetesCert
        Cert::{ cn = "system:kube-proxy", o = Some "system:node-proxier" }

let kubeSchedulerCert =
      mkKubernetesCert
        Cert::{ cn = "system:kube-scheduler", o = Some "system:kube-scheduler" }

let kubernetesCert =
      mkKubernetesCert
        Cert::{
        , cn = "kubernetes"
        , altIPs = [ "10.244.0.1" ] # settings.serverIPs # [ "127.0.0.1" ]
        , altNames =
          [ "kubernetes"
          , "kubernetes.default"
          , "kubernetes.default.svc"
          , "kubernetes.default.svc.cluster"
          , "kubernetes.default.svc.cluster.local"
          ]
        }

let serviceAccountCert = mkKubernetesCert Cert::{ cn = "service-accounts" }

in  { admin = adminCert
    , kubelet = kubletCert
    , kubeControllerManager = kubeControllerManagerCert
    , kubeProxy = kubeProxyCert
    , kubeScheduler = kubeSchedulerCert
    , kubernetes = kubernetesCert
    , serviceAccount = serviceAccountCert
    }
