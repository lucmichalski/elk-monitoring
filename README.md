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

