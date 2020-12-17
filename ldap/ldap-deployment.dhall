let kube = (../packages.dhall).kubernetes

let api = ../api.dhall

let utils = ../utils.dhall

let globalSettings = ../settings.dhall

let volumeName = "ldap-data"

let certVolume = "ldap-certs"

let ldapContainer =
      kube.Container::{
      , name = "openldap"
      , image = Some "registry.hub.docker.com/osixia/openldap:1.3.0"
      , env = Some
          [ kube.EnvVar::{
            , name = "LDAP_ORGANISATION"
            , value = Some globalSettings.organizationName
            }
          , kube.EnvVar::{
            , name = "LDAP_DOMAIN"
            , value = Some (utils.NonEmpty.head Text globalSettings.hosts)
            }
          , kube.EnvVar::{ name = "KEEP_EXISTING_CONFIG", value = Some "true" }
          , kube.EnvVar::{ name = "LDAP_TLS_ENFORCE", value = Some "true" }
          ]
      , ports = Some
          [ kube.ContainerPort::{ containerPort = 636, name = Some "ldaps" } ]
      , volumeMounts = Some
          [ kube.VolumeMount::{
            , mountPath = "/var/lib/ldap"
            , name = volumeName
            , subPath = Some "data"
            }
          , kube.VolumeMount::{
            , mountPath = "/etc/ldap/slapd.d"
            , name = volumeName
            , subPath = Some "config"
            }
          , kube.VolumeMount::{
            , mountPath = "/container/service/slapd/assets/certs"
            , name = certVolume
            }
          ]
      }

in    λ(input : ./Settings.dhall)
    → let config =
            api.SimpleDeployment::{
            , name = "openldap"
            , namespace = input.namespace
            , containers = [ ldapContainer ]
            , ingress = api.noIngress
            , volumes =
                [ kube.Volume::{
                  , name = volumeName
                  , persistentVolumeClaim =
                      Some { claimName = input.claimName, readOnly = None Bool }
                  }
                ]
            }

      let certs =
            api.Certs::{
            , volumeName = certVolume
            , caCerts = [ api.Certs.File::{ name = "ca" } ]
            , certs = [ api.Certs.File::{ name = "ldap" } ]
            }

      in  api.mkStatefulSet (api.withCerts certs config)
