locals {
  default_table_mappings = jsonencode({
    rules = [
      {
        rule-type = "selection"
        rule-id   = "1"
        rule-name = "include-all"
        object-locator = {
          schema-name = "%"
          table-name  = "%"
        }
        rule-action = "include"
      }
    ]
  })

  default_task_settings = jsonencode({
    TargetMetadata = {
      TargetSchema                 = ""
      SupportLobs                  = true
      FullLobMode                  = false
      LobChunkSize                 = 64
      LimitedSizeLobMode           = true
      LobMaxSize                   = 32768
      InlineLobMaxSize             = 0
      LoadMaxFileSize              = 0
      ParallelLoadThreads          = 0
      ParallelLoadBufferSize       = 0
      ParallelLoadQueuesPerThread  = 0
      ParallelApplyThreads         = 0
      ParallelApplyBufferSize      = 0
      ParallelApplyQueuesPerThread = 0
      BatchApplyEnabled            = false
    }
    FullLoadSettings = {
      TargetTablePrepMode             = "DROP_AND_CREATE"
      CreatePkAfterFullLoad           = false
      StopTaskCachedChangesApplied    = false
      StopTaskCachedChangesNotApplied = false
      MaxFullLoadSubTasks             = 8
      TransactionConsistencyTimeout   = 600
      CommitRate                      = 50000
    }
    Logging = {
      EnableLogging = true
      LogComponents = [
        { Id = "TRANSFORMATION", Severity = "LOGGER_SEVERITY_DEFAULT" },
        { Id = "SOURCE_UNLOAD", Severity = "LOGGER_SEVERITY_DEFAULT" },
        { Id = "IO", Severity = "LOGGER_SEVERITY_DEFAULT" },
        { Id = "TARGET_LOAD", Severity = "LOGGER_SEVERITY_DEFAULT" },
        { Id = "TASK_MANAGER", Severity = "LOGGER_SEVERITY_DEFAULT" }
      ]
    }
    ControlTablesSettings = {
      historyTimeslotInMinutes      = 5
      StatusTableEnabled            = false
      SuspendedTablesTableEnabled   = false
      HistoryTimeslotInMinutes      = 5
      controlSchema                 = ""
      HistoryTableEnabled           = false
      FullLoadExceptionTableEnabled = false
    }
    StreamBufferSettings = {
      StreamBufferCount        = 3
      StreamBufferSizeInMB     = 8
      CtrlStreamBufferSizeInMB = 5
    }
    ChangeProcessingDdlHandlingPolicy = {
      HandleSourceTableDropped   = true
      HandleSourceTableTruncated = true
      HandleSourceTableAltered   = true
    }
    ErrorBehavior = {
      DataErrorPolicy                      = "LOG_ERROR"
      DataTruncationErrorPolicy            = "LOG_ERROR"
      DataErrorEscalationPolicy            = "SUSPEND_TABLE"
      DataErrorEscalationCount             = 0
      TableErrorPolicy                     = "SUSPEND_TABLE"
      TableErrorEscalationPolicy           = "STOP_TASK"
      TableErrorEscalationCount            = 0
      RecoverableErrorCount                = -1
      RecoverableErrorInterval             = 5
      RecoverableErrorThrottling           = true
      RecoverableErrorThrottlingMax        = 1800
      ApplyErrorDeletePolicy               = "IGNORE_RECORD"
      ApplyErrorInsertPolicy               = "LOG_ERROR"
      ApplyErrorUpdatePolicy               = "LOG_ERROR"
      ApplyErrorEscalationPolicy           = "LOG_ERROR"
      ApplyErrorEscalationCount            = 0
      FullLoadIgnoreConflicts              = true
      FailOnTransactionConsistencyBreached = false
      FailOnNoTablesCaptured               = false
    }
  })
}

resource "aws_dms_replication_task" "this" {
  for_each = var.replication_tasks

  replication_task_id       = each.key
  replication_instance_arn  = aws_dms_replication_instance.this[each.value.replication_instance_key].replication_instance_arn
  source_endpoint_arn       = aws_dms_endpoint.this[each.value.source_endpoint_key].endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.this[each.value.target_endpoint_key].endpoint_arn
  migration_type            = each.value.migration_type
  table_mappings            = coalesce(each.value.table_mappings, local.default_table_mappings)
  replication_task_settings = each.value.replication_task_settings != null ? each.value.replication_task_settings : local.default_task_settings
  start_replication_task    = each.value.start_replication_task
  cdc_start_time            = each.value.cdc_start_time

  tags = merge(var.tags, each.value.tags)
}
