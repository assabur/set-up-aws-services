{
  "Comment": "An example of the Amazon States Language for running jobs on Amazon EMR",
  "StartAt": "Create an EMR cluster",
  "QueryLanguage": "JSONata",
  "States": {
    "Create an EMR cluster": {
      "Type": "Task",
      "Resource": "arn:aws:states:::elasticmapreduce:createCluster.sync",
      "Arguments": {
        "Name": "${cluster_name}",
        "VisibleToAllUsers": true,
        "ReleaseLabel": "${emr_release_label}",
        "Applications": [
          { "Name": "Spark" }
        ],
        "ServiceRole": "${emr_service_role_name}",
        "JobFlowRole": "${emr_instance_profile_name}",
        "LogUri": "${emr_log_uri}",
        "Tags": [
          {"Key": "for-use-with-amazon-emr-managed-policies", "Value": "true"}
        ],
        "Instances": {
          "KeepJobFlowAliveWhenNoSteps": true,
          "InstanceFleets": [
            {
              "Name": "MyMasterFleet",
              "InstanceFleetType": "MASTER",
              "TargetOnDemandCapacity": 1,
              "InstanceTypeConfigs": [
                { "InstanceType": "${master_instance_type}" }
              ]
            },
            {
              "Name": "MyCoreFleet",
              "InstanceFleetType": "CORE",
              "TargetOnDemandCapacity": 1,
              "InstanceTypeConfigs": [
                { "InstanceType": "${core_instance_type}" }
              ]
            }
          ]
        }
      },
      "Assign": {
        "clusterId": "{% $states.result.ClusterId %}"
      },
      "Next": "Run first step"
    },
    "Run Spark aggregation": {
      "Type": "Task",
      "Resource": "arn:aws:states:::elasticmapreduce:addStep.sync",
      "Arguments": {
        "ClusterId": "{% $clusterId %}",
        "Step": {
          "Name": "Salary aggregations with PySpark",
          "ActionOnFailure": "TERMINATE_CLUSTER",
          "HadoopJarStep": {
            "Jar": "command-runner.jar",
            "Args": [
              "spark-submit",
              "--deploy-mode",
              "cluster",
              "{% $spark_script_s3_uri %}",
              "--input",
              "{% $salary_input_s3_uri %}",
              "--output",
              "{% $salary_output_s3_uri %}"
            ]
          }
        }
      },
      "Retry": [
        {
          "ErrorEquals": ["States.ALL"],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "Next": "Terminate Cluster"
    },
    "Terminate Cluster": {
      "Type": "Task",
      "Resource": "arn:aws:states:::elasticmapreduce:terminateCluster",
      "Arguments": {
        "ClusterId": "{% $clusterId %}"
      },
      "End": true
    }
  }
}
