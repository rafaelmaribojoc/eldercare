/// Represents a distinct step in an approval workflow
class WorkflowStep {
  final String id;
  final String label;
  final String description;
  final List<String> requiredRoles; // Roles allowed to approve this step
  final String?
      nextStepId; // The ID of the next step, or null if this is the final step
  final String?
      signatureFieldName; // The docx field name for this step's signature (e.g. 'noted_by', 'center_head_name')

  // Future extensibility:
  // final List<String> notifyRoles;
  // final Map<String, dynamic> metadata;

  const WorkflowStep({
    required this.id,
    required this.label,
    required this.description,
    required this.requiredRoles,
    this.nextStepId,
    this.signatureFieldName,
  });
}

/// Configuration for a specific form template's workflow
class WorkflowConfig {
  final String templateId;
  final Map<String, WorkflowStep> steps;
  final String initialStepId;

  const WorkflowConfig({
    required this.templateId,
    required this.steps,
    required this.initialStepId,
  });

  WorkflowStep? getStep(String stepId) => steps[stepId];

  WorkflowStep get initialStep => steps[initialStepId]!;
}
