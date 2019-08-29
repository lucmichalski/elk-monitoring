db.createUser({
    user: "mongodb_exporter",
    pwd: "s3cr3tpassw0rd",
    roles: [ 
        { role: "clusterMonitor", db: "admin" },
        { role: "read", db: "local" }
    ]
})
  
db.users.insert({
    name: "mongodb_exporter"
})