let utils = ./utils.dhall

let hosts =
      utils.NonEmpty.create
        Text
        "cerberus-systems.de"
        [ "cerberus-systems.com" ]

in  { hosts = hosts
    , serverIPs = [ "5.189.142.109", "192.168.99.100" ]
    , caValidDays = 1826
    , countryName = "DE"
    , stateOrProvinceName = "Bayern"
    , localityName = "München"
    , postalCode = 80939
    , streetAddress = "Schlößlanger 5"
    , organizationName = "Cerberus Systems"
    , organizationalUnitName = None Text
    , commonName = "Cerberus Systems Root Certificate Authority"
    , emailAddress = "ca@cerberus-systems.de"
    , userEmail = "jan@vanbruegge.de"
    , authInfoAccess = "https://static.cerberus-systems.de/certs/ca.crt"
    }
