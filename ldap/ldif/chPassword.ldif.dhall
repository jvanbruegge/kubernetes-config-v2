  λ(adminSHA : Text)
→ λ(configSHA : Text)
→ ''
  dn: olcDatabase={1}mdb,cn=config
  changetype: modify
  replace: olcRootPW
  olcRootPW: ${adminSHA}

  dn: olcDatabase={0}config,cn=config
  changetype: modify
  replace: olcRootPW
  olcRootPW: ${configSHA}
  ''
