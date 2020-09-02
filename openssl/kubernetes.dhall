let openssl = (../packages.dhall).openssl

let utils = ../utils.dhall

let settings = ../settings.dhall

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

let mkCert =
        λ(subdomain : Text)
      → λ(server : Bool)
      → let newHosts =
              utils.NonEmpty.map
                Text
                Text
                (λ(host : Text) → "${subdomain}.${host}")
                settings.hosts

        in  openssl.mkConfig
              openssl.Config::{
              , distinguishedName = openssl.DistinguishedName::{
                , commonName = newHosts.head
                }
              , altNames = utils.NonEmpty.toList Text newHosts
              , usage =
                    openssl.Config.default.usage
                  # [       if server

                      then  openssl.KeyUsage.ServerAuth

                      else  openssl.KeyUsage.ClientAuth
                    ]
              }

in  { kubernetesCA = kubernetesCA
    , etcdCA = etcdCA
    , frontProxyCA = frontProxyCA
    , kubeApiserver = kubeApiserverCert
    , kubeApiserverKubeletClient = kubeApiserverKubeletClientCert
    , vault = mkCert "vault" True
    , vault-operator = mkCert "vault-operator" False
    }
