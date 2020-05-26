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

let kubernetesCA =
      openssl.mkCaConfig
        openssl.CaConfig::{
        , distinguishedName = openssl.DistinguishedName::{
          , commonName = "kubernetes-ca"
          }
        , allowedHosts = [] : List Text
        , caDir = "ca/kubernetesCA"
        }

let etcdCA =
      openssl.mkCaConfig
        openssl.CaConfig::{
        , distinguishedName = openssl.DistinguishedName::{
          , commonName = "etcd-ca"
          }
        , allowedHosts = [] : List Text
        , caDir = "ca/kubernetesCA"
        }

let frontProxyCA =
      openssl.mkCaConfig
        openssl.CaConfig::{
        , distinguishedName = openssl.DistinguishedName::{
          , commonName = "kubernetes-front-proxy-ca"
          }
        , allowedHosts = [] : List Text
        , caDir = "ca/frontProxyCA"
        }

let adminCert =
      mkKubernetesCert
        Cert::{ cn = "kubernetes-admin", o = Some "system:masters" }

let kubletCert =
      mkKubernetesCert
        Cert::{
        , cn = "system:node:kube-master"
        , o = Some "system:nodes"
        , altIPs = settings.serverIPs
        }

let kubeControllerManagerCert =
      mkKubernetesCert Cert::{ cn = "system:kube-controller-manager" }

let kubeSchedulerCert =
      mkKubernetesCert
        Cert::{ cn = "system:kube-scheduler", o = Some "system:kube-scheduler" }

let serviceAccountCert = mkKubernetesCert Cert::{ cn = "service-accounts" }

in  { admin = adminCert
    , kubelet = kubletCert
    , kubeControllerManager = kubeControllerManagerCert
    , kubeScheduler = kubeSchedulerCert
    , serviceAccount = serviceAccountCert
    , kubernetesCA = kubernetesCA
    , etcdCA = etcdCA
    , frontProxyCA = frontProxyCA
    }
