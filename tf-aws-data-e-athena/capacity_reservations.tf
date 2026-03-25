resource "aws_athena_capacity_reservation" "this" {
  for_each = var.capacity_reservations

  name        = each.key
  target_dpus = each.value.target_dpus

  dynamic "capacity_assignment_configuration" {
    for_each = length(each.value.workgroup_assignments) > 0 ? [each.value.workgroup_assignments] : []

    content {
      dynamic "capacity_assignment" {
        for_each = capacity_assignment_configuration.value

        content {
          workgroup_names = [capacity_assignment.value]
        }
      }
    }
  }

  tags = var.tags
}
