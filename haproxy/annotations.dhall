{ sslPassthrough =
    { mapKey = "ingress.kubernetes.io/ssl-passthrough", mapValue = "true" }
, sslRedirect =
    { mapKey = "ingress.kubernetes.io/ssl-redirect", mapValue = "true" }
}
