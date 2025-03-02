#!/bin/bash

# Test MySQL
echo "Testing MySQL..."
mariadb -h mariadb.mariadb.svc.cluster.local -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;" && echo "MySQL connection successful!" || echo "MySQL connection failed!"

# Test PostgreSQL
echo "Testing PostgreSQL..."
PGPASSWORD="$POSTGRES_PASSWORD" psql -h postgres.postgres.svc.cluster.local -U postgres -c "\l" && echo "PostgreSQL connection successful!" || echo "PostgreSQL connection failed!"

# Test Redis
echo "Testing Redis..."
redis-cli -h redis.redis.svc.cluster.local -a "$REDIS_PASSWORD" PING && echo "Redis connection successful!" || echo "Redis connection failed!"

## Test Altri Servizi (es. HTTP)
#echo "Testing demo-go Service..."
#curl -I http://demo-go:80 && echo "HTTP demo-go service connection successful!" || echo "HTTP demo-go service connection failed!"