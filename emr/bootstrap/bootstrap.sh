#!/bin/bash

# EMR Bootstrap Script for Salary Aggregation Job
# This script configures the EMR cluster for optimal PySpark performance
# Each line is explained in the README for educational purposes

echo "Starting EMR bootstrap configuration..."

# Line 1: Set Spark configuration for small clusters
# Reduces shuffle partitions to prevent excessive overhead on small datasets
echo "Configuring Spark settings for small cluster..."
sudo mkdir -p /etc/spark/conf
sudo bash -c 'cat > /etc/spark/conf/spark-defaults.conf << EOF
spark.sql.shuffle.partitions 8
spark.sql.adaptive.enabled true
spark.sql.adaptive.coalescePartitions.enabled true
spark.sql.adaptive.advisoryPartitionSizeInBytes 64MB
spark.serializer org.apache.spark.serializer.KryoSerializer
EOF'

# Line 2: Set environment variables for optimal performance
# Ensures Python 3 is used for PySpark and sets Spark configuration directory
echo "Setting environment variables..."
sudo bash -c 'cat >> /etc/profile << EOF
export PYSPARK_PYTHON=/usr/bin/python3
export SPARK_CONF_DIR=/etc/spark/conf
EOF'

# Line 3: Optimize JVM settings for small instances
# Reduces memory allocation to prevent OOM on small instances
echo "Optimizing JVM settings for small instances..."
sudo bash -c 'cat > /etc/spark/conf/spark-env.sh << EOF
export SPARK_EXECUTOR_MEMORY=1G
export SPARK_DRIVER_MEMORY=1G
export SPARK_EXECUTOR_CORES=1
EOF'

# Line 4: Create log directory for custom applications
# Provides centralized location for application logs
echo "Creating application log directory..."
sudo mkdir -p /var/log/emr-applications
sudo chmod 755 /var/log/emr-applications

echo "Bootstrap configuration completed successfully!"
echo "Spark optimizations applied for small cluster processing."
