### PROMETHEUS
docker run -d --name prometheus --link mysql-exporter:mysql-exporter -v $PWD/prom/prometheus.yml:/etc/prometheus/prometheus.yml -p 9090:9090 prom/prometheus

### MYSQL
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

###### Enable slow logs
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 3;
SET GLOBAL slow_query_log_file = '/var/log/mysql/slowlog.log';
show global variables like '%slow%';

slow-launch-time                                             1
slow-query-log                                               TRUE
slow-query-log-file                                          /var/lib/mysql/d293d87e0ff1-slow.log


### DOCKER

/etc/docker/daemon.json
{
	"experimental": true,
	"metrics-addr": "0.0.0.0:9323"
}

OR

dockerd --debug --metrics-addr 0.0.0.0:9323 --experimental

### NODE

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

### MONGO

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

### HAPROXY

docker-compose -f haproxy_cluster/docker-compose.yaml up -d

docker run -d -p 9101:9101 \
    --name haproxy-exporter \
    --link ha:ha \
    prom/haproxy-exporter \
    --haproxy.scrape-uri="http://admin:password@ha:8404/haproxy?stats;csv" \
    --log.level="info"

### NGINX

docker build -t ngx_stat -f nginx_status/Dockerfile ./nginx_status/.
docker run -d --name ngx_stat ngx_stat
docker run -ti --rm --link ngx_stat:ngxstat nginx:alpine sh
docker run -d --name ngx-exporter \
    -p 9113:9113 --link ngx_stat:ngxstat  \
    nginx/nginx-prometheus-exporter:0.4.2 \
    -nginx.scrape-uri http://ngxstat:9898/status

###### NGINX VTS
docker build -t ngxvts -f nginx_status/vts/Dockerfile ./nginx_status/vts/.
docker run -d --name ngxvts ngxvts
docker run -ti --rm --link ngxvts:ngxvts nginx:alpine sh
docker run -d --name ngx-vts-exporter \
    -p 9913:9913 \
    --link ngxvts:ngxvts \
    -e NGINX_HOST="http://ngxvts:8080/status/format/json" \
    sophos/nginx-vts-exporter

### CADVISOR

docker run -d  \
    -v /:/rootfs:ro \
    -v /var/run:/var/run:ro \
    -v /sys:/sys:ro \
    -v /var/lib/docker/:/var/lib/docker:ro \
    -v /dev/disk/:/dev/disk:ro \
    -p 32880:8080 \
    --name=cadvisor \
    google/cadvisor

### MEMCACHED

docker run -d --name memcached-exporter \
    -p 9150:9150 \
    quay.io/prometheus/memcached-exporter \
    --memcached.address 192.168.1.46:11212

### PHP_FPM

docker run -d --rm \
    -p 9253:9253 \
    -e PHP_FPM_SCRAPE_URI="tcp://192.168.1.46:9000/status" \
    hipages/php-fpm_exporter

#### Prometheus metrics query
({__name__=~'go_.*', job='haproxy'})

#### For grafana php-fpm
{instance=~"^$Host$"}

#### For grafana mongo
{instance=~"$env"}

### Test filesystem disk available
fallocate -l 10G test.img