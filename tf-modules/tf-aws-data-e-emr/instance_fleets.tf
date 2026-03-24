###############################################################################
# EMR Instance Fleet Configurations
# Note: Instance fleets are configured as part of aws_emr_cluster resources.
# This file provides locals and supporting configuration for fleet-based clusters.
###############################################################################

locals {
  # Recommended instance type families for fleet diversification
  fleet_general_purpose = [
    "m5.xlarge", "m5.2xlarge", "m5a.xlarge", "m5a.2xlarge",
    "m6i.xlarge", "m6i.2xlarge", "m6a.xlarge", "m6a.2xlarge"
  ]

  fleet_memory_optimized = [
    "r5.xlarge", "r5.2xlarge", "r5a.xlarge", "r5a.2xlarge",
    "r6i.xlarge", "r6i.2xlarge", "r6a.xlarge", "r6a.2xlarge"
  ]

  fleet_compute_optimized = [
    "c5.2xlarge", "c5.4xlarge", "c5a.2xlarge", "c5a.4xlarge",
    "c6i.2xlarge", "c6i.4xlarge", "c6a.2xlarge", "c6a.4xlarge"
  ]

  fleet_gpu_instances = [
    "p3.2xlarge", "p3.8xlarge", "g4dn.xlarge", "g4dn.2xlarge"
  ]

  # EMR application configuration presets
  spark_defaults_config = jsonencode([
    {
      Classification = "spark-defaults"
      Properties = {
        "spark.dynamicAllocation.enabled"               = "true"
        "spark.dynamicAllocation.minExecutors"          = "1"
        "spark.dynamicAllocation.maxExecutors"          = "100"
        "spark.sql.adaptive.enabled"                    = "true"
        "spark.sql.adaptive.coalescePartitions.enabled" = "true"
        "spark.serializer"                              = "org.apache.spark.serializer.KryoSerializer"
        "spark.sql.parquet.compression.codec"           = "snappy"
      }
    },
    {
      Classification = "spark-env"
      Configurations = [
        {
          Classification = "export"
          Properties = {
            PYSPARK_PYTHON = "/usr/bin/python3"
          }
        }
      ]
    },
    {
      Classification = "yarn-site"
      Properties = {
        "yarn.nodemanager.vmem-check-enabled" = "false"
        "yarn.nodemanager.pmem-check-enabled" = "false"
      }
    }
  ])

  hive_defaults_config = jsonencode([
    {
      Classification = "hive-site"
      Properties = {
        "hive.metastore.client.factory.class"      = "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"
        "hive.metastore.schema.verification"       = "false"
        "hive.exec.dynamic.partition"              = "true"
        "hive.exec.dynamic.partition.mode"         = "nonstrict"
        "hive.exec.max.dynamic.partitions"         = "10000"
        "hive.exec.max.dynamic.partitions.pernode" = "1000"
        "hive.tez.container.size"                  = "4096"
        "hive.tez.java.opts"                       = "-Xmx3276m"
      }
    },
    {
      Classification = "tez-site"
      Properties = {
        "tez.am.resource.memory.mb" = "4096"
        "tez.am.java.opts"          = "-Xmx3276m"
      }
    }
  ])
}
