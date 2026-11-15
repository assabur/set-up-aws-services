import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import functions as SqlFuncs

def sparkAggregate(glueContext, parentFrame, groups, aggs, transformation_ctx) -> DynamicFrame:
    aggsFuncs = []
    for column, func in aggs:
        aggsFuncs.append(getattr(SqlFuncs, func)(column))
    result = parentFrame.toDF().groupBy(*groups).agg(*aggsFuncs) if len(groups) > 0 else parentFrame.toDF().agg(*aggsFuncs)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Script generated for node sourceS3
sourceS3_node1760388735910 = glueContext.create_dynamic_frame.from_options(format_options={"quoteChar": "\"", "withHeader": True, "separator": ",", "optimizePerformance": False}, connection_type="s3", format="csv", connection_options={"paths": ["s3://data-mentoring-dev-bucket/salary-data.csv"], "recurse": False}, transformation_ctx="sourceS3_node1760388735910")

# Script generated for node Aggregate
Aggregate_node1760388964314 = sparkAggregate(glueContext, parentFrame = sourceS3_node1760388735910, groups = ["gender", "department"], aggs = [["grosspay", "avg"]], transformation_ctx = "Aggregate_node1760388964314")

# Script generated for node targetS3
targetS3_node1760389050827 = glueContext.getSink(path="s3://data-mentoring-dev-bucket/gold/", connection_type="s3", updateBehavior="UPDATE_IN_DATABASE", partitionKeys=[], enableUpdateCatalog=True, transformation_ctx="targetS3_node1760389050827")
targetS3_node1760389050827.setCatalogInfo(catalogDatabase="human_resources",catalogTableName="salary_aggregated_terraform")
targetS3_node1760389050827.setFormat("glueparquet", compression="snappy")
targetS3_node1760389050827.writeFrame(Aggregate_node1760388964314)
job.commit()