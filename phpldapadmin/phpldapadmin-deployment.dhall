let kube = (../packages.dhall).kubernetes

let api = ../api.dhall

let utils = ../utils.dhall

let certVolume = "ldap-certs"

let globalSettings = ../settings.dhall

let phpldapadmin_config =
      "#PYTHON2BASH:[{'ldaps://ldap.cerberus-systems.de:636/': [{'server': [{'tls': 'false', 'base': 'array(\\'cn=config\\', \\'dc=cerberus-systems,dc=de\\')'}]}]}]"

let host = utils.NonEmpty.head Text globalSettings.hosts

let adminContainer =
      kube.Container::{
      , name = "phpldapadmin"
      , image = Some "registry.hub.docker.com/cerberussystems/phpldapadmin:0.9.2"
      , env = Some
          [ kube.EnvVar::{ name = "PHPLDAPADMIN_SERVER_PATH", value = Some "/" }
          , kube.EnvVar::{ name = "PHPLDAPADMIN_HTTPS", value = Some "true" }
          , kube.EnvVar::{ name = "PHPLDAPADMIN_HTTPS_VERIFY_CLIENT", value = Some "require" }
          , kube.EnvVar::{ name = "PHPLDAPADMIN_HTTPS_VERIFY_DEPTH", value = Some "2" }
          , kube.EnvVar::{
            , name = "PHPLDAPADMIN_LDAP_HOSTS"
            , value = Some phpldapadmin_config
            }
          , kube.EnvVar::{
            , name = "HOSTNAME"
            , value = Some "phpldapadmin.${host}"
            }
          ]
      , ports = Some
          [ kube.ContainerPort::{ containerPort = +443, name = Some "https" } ]
      , volumeMounts = Some
          [ kube.VolumeMount::{
            , mountPath = "/container/service/ldap-client/assets/certs"
            , name = certVolume
            , subPath = Some "ldap"
            }
          , kube.VolumeMount::{
            , mountPath = "/container/service/phpldapadmin/assets/apache2/certs"
            , name = certVolume
            , subPath = Some "https"
            }
          ]
      }

in    λ(settings : ./Settings.dhall)
    → let config =
            api.SimpleDeployment::{
            , name = "phpldapadmin"
            , namespace = settings.namespace
            , containers = [ adminContainer ]
            , ingress = api.sslPassthrough
            }

      let certs =
            api.Certs::{
            , volumeName = certVolume
            , caCerts =
                [ api.Certs.File::{ name = "ldap-ca", subdir = Some "ldap" }
                , api.Certs.File::{ name = "ca", subdir = Some "https" }
                ]
            , certs =
                [ api.Certs.File::{ name = "ldap-client", subdir = Some "ldap" }
                , api.Certs.File::{
                  , name = "phpldapadmin"
                  , subdir = Some "https"
                  }
                ]
            }

      in  api.mkDeployment (api.withCerts certs config)
