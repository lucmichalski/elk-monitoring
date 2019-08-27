docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=MySecretPa55word -d mysql
docker run -it --rm  --link some-mysql:some-mysql mysql mysql -hsome-mysql -uroot -p

CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'HardPaSSw0rd';
GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'exporter'@'localhost';
GRANT SELECT ON performance_schema.* TO 'exporter'@'localhost';

docker run -d --name mysql-exporter -p 9104:9104 --link some-mysql:some-mysql -e DATA_SOURCE_NAME="exporter:HardPaSSw0rd@(some-mysql:3306)/" prom/mysqld-exporter \
--collect.info_schema.processlist \
--collect.info_schema.innodb_metrics \
--collect.info_schema.tablestats \
--collect.info_schema.tables \
--collect.info_schema.userstats


docker run -d --name prometheus --link mysql-exporter:mysql-exporter -v $PWD/prom/prometheus.yml:/etc/prometheus/prometheus.yml -p 9090:9090 prom/prometheus


/etc/docker/daemon.json
{
	"experimental": true,
	"metrics-addr": "0.0.0.0:9323"
}

OR

dockerd --debug --metrics-addr 0.0.0.0:9323 --experimental

sudo useradd --no-create-home --shell /bin/false node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
tar vxzf node_exporter-0.18.1.linux-amd64.tar.gz
sudo cp node_exporter-0.18.1.linux-amd64/node_exporter /usr/local/bin
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo vim /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target

…
ExecStart=/usr/local/bin/node_exporter --collectors.enabled meminfo,loadavg,filesystem
…

sudo systemctl daemon-reload
sudo systemctl start node_exporter

docker run -d --name some-mongo \
    -e MONGO_INITDB_ROOT_USERNAME=root \
    -e MONGO_INITDB_ROOT_PASSWORD=secret \
    mongo:3
docker run -it --rm \
    --link some-mongo:some-mongo \
    mongo mongo "mongodb://root:secret@some-mongo:27017"

db.getSiblingDB("admin").createUser({
    user: "mongodb_exporter",
    pwd: "s3cr3tpassw0rd",
    roles: [
        { role: "clusterMonitor", db: "admin" },
        { role: "read", db: "local" }
    ]
})

docker run -d --name mongo-exporter \
    --link some-mongo:some-mongo \
    -p 9204:9204 \
    -logtostderr \
    eses/mongodb_exporter  \
    -mongodb.uri mongodb://mongodb_exporter:s3cr3tpassw0rd@some-mongo:27017 \
    -web.listen-address=":9204"