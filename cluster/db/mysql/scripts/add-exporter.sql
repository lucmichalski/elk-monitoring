CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'HardPaSSw0rd';
CREATE USER 'exporter'@'%' IDENTIFIED BY 'HardPaSSw0rd';
GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'exporter'@'localhost';
GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'exporter'@'%';
GRANT SELECT ON performance_schema.* TO 'exporter'@'localhost';
GRANT SELECT ON performance_schema.* TO 'exporter'@'%';