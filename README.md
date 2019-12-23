### PROMETHEUS
docker run -d --name prometheus --link mysql-exporter:mysql-exporter -v $PWD/prom/prometheus.yml:/etc/prometheus/prometheus.yml -p 9090:9090 prom/prometheus

### MYSQL
docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=MySecretPa55word -d mysql
docker run -it --rm  --link some-mysql:some-mysql mysql mysql -hsome-mysql -uroot -p

CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'HardPaSSw0rd';
GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'exporter'@'localhost';
GRANT SELECT ON performance_schema.* TO 'exporter'@'localhost';
###### Bare-metal exporter
useradd --no-create-home --shell /bin/false mysql_exporter
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.12.1/mysqld_exporter-0.12.1.linux-amd64.tar.gz
tar vxzf mysqld_exporter-0.12.1.linux-amd64.tar.gz
cp mysqld_exporter-0.12.1.linux-amd64/mysqld_exporter /usr/bin/mysqld_exporter_a
chown mysqld_exporter. /usr/bin/mysqld_exporter_a
vi /etc/systemd/system/mysqld_exporter.service
[Unit]
Description=MySQL Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=mysqld_exporter
Group=mysqld_exporter
Type=simple
ExecStart=/usr/bin/mysqld_exporter

[Install]
WantedBy=multi-user.target

sudo systemctl daemon-reload
sudo systemctl start mysqld_exporter

###### Docker exporter
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

###### NGINX bare-metal

sudo useradd --no-create-home --shell /bin/false nginx_exporter
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.4.2/nginx-prometheus-exporter-0.4.2-linux-amd64.tar.gz
tar vxzf nginx-prometheus-exporter-0.4.2-linux-amd64.tar.gz
sudo cp nginx-prometheus-exporter /usr/bin
sudo chown nginx_exporter:nginx_exporter /usr/bin/nginx-prometheus-exporter
sudo vi /etc/systemd/system/nginx_exporter.service
[Unit]
Description=Nginx Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=nginx_exporter
Group=nginx_exporter
Type=simple
ExecStart=/usr/bin/nginx-prometheus-exporter

[Install]
WantedBy=multi-user.target

sudo systemctl daemon-reload
sudo systemctl start nginx_exporter

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
###### Bare metal
useradd --no-create-home --shell /bin/false memcached_exporter
wget https://github.com/prometheus/memcached_exporter/releases/download/v0.6.0/memcached_exporter-0.6.0.linux-amd64.tar.gz
tar vxzf memcached_exporter-0.6.0.linux-amd64.tar.gz
cp memcached_exporter-0.6.0.linux-amd64/memcached_exporter /usr/bin
chown memcached_exporter:memcached_exporter /usr/bin/memcached_exporter
vi /etc/systemd/system/memcached_exporter.service
[Unit]
Description=Memcached Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=memcached_exporter
Group=memcached_exporter
Type=simple
ExecStart=/usr/bin/memcached_exporter

[Install]
WantedBy=multi-user.target

systemctl daemon-reload
systemctl start memcached_exporter

###### Docker version
docker run -d --name memcached-exporter \
    -p 9150:9150 \
    quay.io/prometheus/memcached-exporter \
    --memcached.address 192.168.1.46:11212

### PHP_FPM

docker run -d --rm \
    -p 9253:9253 \
    -e PHP_FPM_SCRAPE_URI="tcp://192.168.1.46:9000/status" \
    hipages/php-fpm_exporter

###### Bare-metal exporter
sudo useradd --no-create-home --shell /bin/false php_exporter
wget https://github.com/hipages/php-fpm_exporter/releases/download/v1.0.0/php-fpm_exporter_1.0.0_linux_amd64
cp php-fpm_exporter_1.0.0_linux_amd64 /usr/bin/php-fpm-exporter
chmod +x /usr/bin/php-fpm-exporter
chown php_exporter:php_exporter /usr/bin/php-fpm-exporter

sudo vi /etc/systemd/system/php_exporter.service
[Unit]
Description=PHP Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=php_exporter
Group=php_exporter
Type=simple
ExecStart=/usr/bin/php-fpm-exporter server --phpfpm.scrape-uri tcp://localhost:7000/php-fpm-status.php --phpfpm.fix-process-count true --web.listen-address :9255

[Install]
WantedBy=multi-user.target

sudo systemctl daemon-reload
sudo systemctl start php_exporter

http://localhost/php-fpm-status.php

#### Prometheus metrics query
({__name__=~'go_.*', job='haproxy'})

#### For grafana php-fpm
{instance=~"^$Host$"}

#### For grafana mongo
{instance=~"$env"}

### Test filesystem disk available
fallocate -l 10G test.img

### ES
###### Show indexes
curl -X GET "localhost:9200/_cat/indices?v&pretty"

curl -X GET "localhost:9200/_search?pretty" -H 'Content-Type: application/json' -d'
{
    "query": {
        "match_all": {}
    }
}
'
