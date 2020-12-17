let openssl = (../packages.dhall).openssl

let settings = ../settings.dhall

in  openssl.mkCaConfig
      openssl.CaConfig::{
      , distinguishedName = openssl.DistinguishedName::{
        , commonName = settings.commonName
        , country = Some settings.countryName
        , emailAddress = Some settings.userEmail
        , locality = Some settings.localityName
        , organization = Some settings.organizationName
        , postalCode = Some (Natural/show settings.postalCode)
        , state = Some settings.stateOrProvinceName
        , streetAddress = Some settings.streetAddress
        }
      , allowedHosts = [] : List Text
      , caDir = "ca"
      }
