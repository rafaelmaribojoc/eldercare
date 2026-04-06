import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Workflow Definitions
# In a production system, this might be loaded from a DB or YAML file.
# For now, it mirrors the Flutter configuration.
WORKFLOW_REGISTRY = {
    # =========================================================================
    # PATTERN 3 (Chain of Command): Social -> Medical -> Center Head
    # =========================================================================
    
    # Admission Slip: SW submits -> Medical reviews -> Center Head approves
    "admission_slip": {
        "transitions": {
            "pending_review": {
                "next_status": "pending_final_approval",
                "required_roles": ["medical_staff", "nurse", "head"],
                "signature_field": "medical_staff_name",
                "notify_roles": ["center_head"],
                "notify_message": "Medical assessment complete. Admission Slip awaits final approval."
            },
            "pending_final_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "center_head_name",
                "notify_roles": ["social_worker"],
                "notify_message": "Admission Slip approved."
            }
        }
    },
    
    # Discharge Slip: SW submits -> Medical reviews -> Center Head approves
    "discharge_slip": {
        "transitions": {
            "pending_review": {
                "next_status": "pending_final_approval",
                "required_roles": ["medical_staff", "nurse", "head"],
                "signature_field": "medical_staff_name",
                "notify_roles": ["center_head"],
                "notify_message": "Medical review complete. Discharge Slip awaits final approval."
            },
            "pending_final_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "center_head_name",
                "notify_roles": ["social_worker", "medical_staff"],
                "notify_message": "Discharge Slip fully approved."
            }
        }
    },

    # =========================================================================
    # PATTERN 3 (Chain of Command): Medical -> Medical Officer -> Center Head
    # =========================================================================
    
    # Report on Special Events: Nurse -> Medical Officer -> Center Head
    "special_events": {
        "transitions": {
            "pending_supervisor": {
                "next_status": "pending_head_approval",
                "required_roles": ["medical_head", "head"],
                "signature_field": "noted_by",
                "notify_roles": ["center_head"],
                "notify_message": "Medical Officer reviewed. Report on Special Events awaits Center Head approval."
            },
            "pending_head_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["medical_staff", "nurse"],
                "notify_message": "Report on Special Events approved."
            }
        }
    },

    # =========================================================================
    # PATTERN 3 (Chain of Command): Homelife -> Supervising HP -> Center Head
    # =========================================================================
    
    # Inventory Upon Admission: HP on Duty -> Supervising HP -> Center Head
    "inventory_admission": {
        "transitions": {
            "pending_supervisor": {
                "next_status": "pending_head_approval",
                "required_roles": ["homelife_head", "head"],
                "signature_field": "noted_by",
                "notify_roles": ["center_head"],
                "notify_message": "Supervising HP reviewed. Inventory (Admission) awaits Center Head approval."
            },
            "pending_head_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["homelife_staff"],
                "notify_message": "Inventory Upon Admission approved."
            }
        }
    },

    # Inventory Upon Discharge: HP on Duty -> Supervising HP -> Center Head
    "inventory_discharge": {
        "transitions": {
            "pending_supervisor": {
                "next_status": "pending_head_approval",
                "required_roles": ["homelife_head", "head"],
                "signature_field": "noted_by",
                "notify_roles": ["center_head"],
                "notify_message": "Supervising HP reviewed. Inventory (Discharge) awaits Center Head approval."
            },
            "pending_head_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["homelife_staff"],
                "notify_message": "Inventory Upon Discharge approved."
            }
        }
    },

    # Monthly Inventory: Staff -> Supervising HP -> Center Head
    "inventory_monthly": {
        "transitions": {
            "pending_supervisor": {
                "next_status": "pending_head_approval",
                "required_roles": ["homelife_head", "head"],
                "signature_field": "noted_by",
                "notify_roles": ["center_head"],
                "notify_message": "Supervising HP reviewed. Monthly Inventory awaits Center Head approval."
            },
            "pending_head_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["homelife_staff"],
                "notify_message": "Monthly Inventory approved."
            }
        }
    },

    # =========================================================================
    # PATTERN 3 (Chain of Command - Long): Out on Pass
    # Homelife -> Supervising HP -> Center Doctor -> Social Worker -> Center Head
    # =========================================================================
    
    "out_on_pass": {
        "transitions": {
            "pending_supervisor": {
                "next_status": "pending_doctor_review",
                "required_roles": ["homelife_head", "head"],
                "signature_field": "supervising_hp",
                "notify_roles": ["medical_head"],
                "notify_message": "Supervising HP approved. Out on Pass awaits Center Doctor clearance."
            },
            "pending_doctor_review": {
                "next_status": "pending_social_worker",
                "required_roles": ["medical_head", "head", "medical_center_doctor", "medical_staff"],
                "signature_field": "center_doctor",
                "notify_roles": ["social_head", "social_worker"],
                "notify_message": "Center Doctor cleared. Out on Pass awaits Social Worker review."
            },
            "pending_social_worker": {
                "next_status": "pending_head_approval",
                "required_roles": ["social_head", "head", "staff", "social_staff", "social_worker"],
                "signature_field": "social_worker",
                "notify_roles": ["center_head"],
                "notify_message": "Social Worker reviewed. Out on Pass awaits Center Head approval."
            },
            "pending_head_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "approved_by",
                "notify_roles": ["homelife_staff"],
                "notify_message": "Out on Pass approved."
            }
        }
    },

    # =========================================================================
    # PATTERN 4 (Roundtable / Parallel): All unit heads -> Center Head
    # =========================================================================
    
    # Incident Report: HP submits -> Supervising HP -> All unit heads sign (parallel) -> Center Head
    "incident_report": {
        "parallel": True,
        "parallel_roles": ["social_head", "medical_head", "psych_head"],
        "transitions": {
            "pending_supervisor": {
                "next_status": "pending_multi_approval",
                "required_roles": ["homelife_head", "head"],
                "signature_field": "attested_by",
                "notify_roles": ["social_head", "medical_head", "psych_head"],
                "notify_message": "Supervising HP reviewed. Incident Report awaits multi-department review."
            },
            "pending_multi_approval": {
                "next_status": "pending_head_approval",
                "required_roles": ["social_head", "medical_head", "psych_head", "head"],
                "signature_field": "received_by",
                "notify_roles": ["center_head"],
                "notify_message": "All unit heads reviewed. Incident Report awaits Center Head approval."
            },
            "pending_head_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["homelife_staff"],
                "notify_message": "Incident Report approved."
            }
        }
    },

    # After Care Plan: SW submits -> HP, Nurse, Psych sign (parallel) -> Center Head
    "after_care_plan": {
        "parallel": True,
        "parallel_roles": ["homelife_head", "medical_head", "psych_head"],
        "transitions": {
            "pending_review": {
                "next_status": "pending_multi_approval",
                "required_roles": ["social_head", "head"],
                "signature_field": "confirmed_social",
                "notify_roles": ["homelife_head", "medical_head", "psych_head"],
                "notify_message": "Social Head reviewed. After Care Plan awaits multi-department review."
            },
            "pending_multi_approval": {
                "next_status": "pending_head_approval",
                "required_roles": ["homelife_head", "medical_head", "psych_head", "head"],
                "signature_field": "noted_by",
                "notify_roles": ["center_head"],
                "notify_message": "All department heads reviewed. After Care Plan awaits Center Head approval."
            },
            "pending_head_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "After Care Plan approved."
            }
        }
    },

    # =========================================================================
    # PATTERN 3 (Chain of Command): Homelife Progress Notes
    # Homelife Staff -> Homelife Head -> Center Head
    # =========================================================================

    "progress_notes": {
        "transitions": {
            "pending_supervisor": {
                "next_status": "pending_head_approval",
                "required_roles": ["homelife_head", "head"],
                "signature_field": "noted_by",
                "notify_roles": ["center_head"],
                "notify_message": "Homelife Head reviewed. Progress Notes awaits Center Head approval."
            },
            "pending_head_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["homelife_staff"],
                "notify_message": "Homelife Progress Notes approved."
            }
        }
    },

    "inventory": {
        "transitions": {
            "pending_supervisor": {
                "next_status": "pending_head_approval",
                "required_roles": ["homelife_head", "head"],
                "signature_field": "submitted_by",
                "notify_roles": ["center_head"],
                "notify_message": "Homelife Head reviewed. Inventory awaits Center Head approval."
            },
            "pending_head_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["homelife_staff"],
                "notify_message": "Inventory approved."
            }
        }
    },


    # =========================================================================
    # PATTERN 5 (Direct Single-Step)
    # =========================================================================

    "inter_service_referral": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["psych_head", "head"],
                "signature_field": "noted_by",
                "notify_roles": [],
                "notify_message": "Inter-Service Referral received by Psych Service."
            }
        }
    },

    # =========================================================================
    # PATTERN 2 (Direct to Center Head): Staff -> Center Head
    # Single-step approval by Center Head
    # =========================================================================

    "admission_case_conference": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Admission Case Conference approved."
            }
        }
    },

    "clients_contract": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Client's Contract approved."
            }
        }
    },

    "ss_progress_notes": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Progress Notes approved."
            }
        }
    },

    "running_notes": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Running Notes approved."
            }
        }
    },

    "intervention_plan": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Intervention Plan approved."
            }
        }
    },

    "updated_social_case_study": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Updated Social Case Study approved."
            }
        }
    },

    "social_case_study": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Social Case Study approved."
            }
        }
    },

    "case_conference": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Case Conference approved."
            }
        }
    },

    "termination_report": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Termination Report approved."
            }
        }
    },

    "closing_summary": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Closing Summary approved."
            }
        }
    },

    "quarterly_narrative": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Quarterly Narrative Report approved."
            }
        }
    },

    "pre_termination_plan": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Pre-Termination Plan approved."
            }
        }
    },

    "case_transfer_summary": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Case Transfer Summary approved."
            }
        }
    },

    "pre_admission_conference": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Pre-Admission Conference approved."
            }
        }
    },

    "kasunduan": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Kasunduan approved."
            }
        }
    },

    "pre_discharge_conference": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["social_worker"],
                "notify_message": "Pre-Discharge Conference approved."
            }
        }
    },

    # Psych Service Pattern 2 forms
    "ps_progress_notes": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["psych_staff"],
                "notify_message": "Psych Progress Notes approved."
            }
        }
    },

    "group_sessions": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["psych_staff"],
                "notify_message": "Group Sessions Report approved."
            }
        }
    },

    "individual_sessions": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["psych_staff"],
                "notify_message": "Individual Sessions Report approved."
            }
        }
    },

    "initial_assessment": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["psych_staff"],
                "notify_message": "Initial Assessment approved."
            }
        }
    },

    "psychometrician_report": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["psych_staff"],
                "notify_message": "Psychometrician's Report approved."
            }
        }
    },

    # Medical Service Pattern 2 forms
    "md_nursing_care_service": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["nurse", "medical_staff"],
                "notify_message": "Nursing Care Service Report approved."
            }
        }
    },

    "md_quarterly_report": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["nurse", "medical_staff"],
                "notify_message": "Medical Quarterly Report approved."
            }
        }
    },

    "md_monthly_accomplishment_report": {
        "transitions": {
            "pending_review": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "noted_by",
                "notify_roles": ["nurse", "medical_staff"],
                "notify_message": "Monthly Accomplishment Report approved."
            }
        }
    },

    # Nutrition Service multi-step workflows
    "nt_malnourished_list": {
        "transitions": {
            "pending_review": {
                "next_status": "pending_doctor_review",
                "required_roles": ["nutrition_head", "head"],
                "signature_field": "noted_by",
                "notify_roles": ["medical_head", "medical_center_doctor", "medical_staff"],
                "notify_message": "Malnourished list needs Center Doctor review."
            },
            "pending_doctor_review": {
                "next_status": "pending_head_approval",
                "required_roles": ["medical_head", "head", "medical_center_doctor", "medical_staff"],
                "signature_field": "mnl_noted_by",
                "notify_roles": ["center_head"],
                "notify_message": "Malnourished list needs Center Head approval."
            },
            "pending_head_approval": {
                "next_status": "approved",
                "required_roles": ["center_head"],
                "signature_field": "approved_by",
                "notify_roles": [],
                "notify_message": "Malnourished list approved."
            }
        }
    },

    "nt_ncp_mnt": {
        "transitions": {
            "pending_review": {
                "next_status": "pending_doctor_review",
                "required_roles": ["nutrition_head", "head"],
                "signature_field": "noted_by",
                "notify_roles": ["medical_head", "medical_center_doctor", "medical_staff"],
                "notify_message": "Nutrition Care Plan needs Center Doctor review."
            },
            "pending_doctor_review": {
                "next_status": "approved",
                "required_roles": ["medical_head", "head", "medical_center_doctor", "medical_staff"],
                "signature_field": "conforme_physician",
                "notify_roles": [],
                "notify_message": "Nutrition Care Plan approved."
            }
        }
    },
}

# Create aliases for prefixed IDs to support both template_id and template_type lookups
_ALIASES = {
    "ss_admission_slip": "admission_slip",
    "ss_discharge_slip": "discharge_slip",
    "md_special_events": "special_events",
    "hl_inventory_admission": "inventory_admission",
    "hl_inventory_discharge": "inventory_discharge",
    "hl_inventory_monthly": "inventory_monthly",
    "hl_out_on_pass": "out_on_pass",
    "hl_incident_report": "incident_report",
    "ss_after_care_plan": "after_care_plan",
    "hl_progress_notes": "progress_notes",
    "ps_inter_service_referral": "inter_service_referral",
    # Pattern 2 aliases (template_id -> template_type)
    "ss_admission_conference": "admission_case_conference",
    "ss_clients_contract": "clients_contract",
    "ss_progress_notes": "ss_progress_notes",
    "ss_running_notes": "running_notes",
    "ss_intervention_plan": "intervention_plan",
    "ss_updated_social_case_study": "updated_social_case_study",
    "ss_social_case_study": "social_case_study",
    "ss_case_conference": "case_conference",
    "ss_termination_report": "termination_report",
    "ss_closing_summary": "closing_summary",
    "ss_quarterly_narrative": "quarterly_narrative",
    "ss_pre_termination_plan": "pre_termination_plan",
    "ss_case_transfer": "case_transfer_summary",
    "ss_pre_admission_conference": "pre_admission_conference",
    "ss_kasunduan": "kasunduan",
    "ss_pre_discharge_conference": "pre_discharge_conference",
    "ps_progress_notes": "ps_progress_notes",
    "ps_group_sessions": "group_sessions",
    "ps_individual_sessions": "individual_sessions",
    "ps_initial_assessment": "initial_assessment",
    "ps_psychometrician_report": "psychometrician_report",
    "md_nursing_care_service": "md_nursing_care_service",
    "md_quarterly_report": "md_quarterly_report",
    "md_monthly_accomplishment_report": "md_monthly_accomplishment_report",
}

for alias, target in _ALIASES.items():
    if target in WORKFLOW_REGISTRY and alias not in WORKFLOW_REGISTRY:
        WORKFLOW_REGISTRY[alias] = WORKFLOW_REGISTRY[target]


class WorkflowEngine:
    @staticmethod
    def get_workflow(template_key):
        """Helper to find workflow config, supporting prefix/template_id variations."""
        if not template_key:
            return None
            
        # 1. Direct match
        if template_key in WORKFLOW_REGISTRY:
            return WORKFLOW_REGISTRY[template_key]
        
        # 2. Try simple suffix match if there's an underscore (hl_inventory -> inventory)
        if "_" in template_key:
            parts = template_key.split("_", 1)
            suffix = parts[1]
            if suffix in WORKFLOW_REGISTRY:
                return WORKFLOW_REGISTRY[suffix]
        
        return None

    @staticmethod
    def get_initial_status(template_type):
        """
        Returns the initial status a form should be set to when submitted.
        For workflow forms, this is the first step ID.
        For non-workflow forms, defaults to 'pending_review'.
        """
        workflow = WorkflowEngine.get_workflow(template_type)
        if not workflow:
            return "pending_review"
        
        transitions = workflow.get("transitions", {})
        # The first key in transitions dict is the initial status
        if transitions:
            return list(transitions.keys())[0]
        return "pending_review"

    @staticmethod
    def is_parallel_workflow(template_type):
        """Check if a workflow uses parallel (roundtable) approval."""
        workflow = WorkflowEngine.get_workflow(template_type)
        if not workflow:
            return False
        return workflow.get("parallel", False)

    @staticmethod
    def get_parallel_roles(template_type):
        """Get the list of roles that must ALL sign for a parallel workflow."""
        workflow = WorkflowEngine.get_workflow(template_type)
        if not workflow:
            return []
        return workflow.get("parallel_roles", [])

    @staticmethod
    def get_next_state(template_type, current_status, user_role, user_unit=None):
        """
        Determines the next state and side effects (notifications) based on workflow config.
        For parallel workflows at the 'pending_multi_approval' step, this returns
        a special 'stay' next_status until all parallel roles have signed.
        The caller must check completed_roles against parallel_roles to decide
        whether to actually advance or stay at the same status.
        """
        workflow = WorkflowEngine.get_workflow(template_type)
        if not workflow:
            # Default behavior for non-workflow forms (Pattern 2):
            # If pending_review -> approved (if role is appropriate)
            if current_status == 'pending_review' and (user_role in ['center_head', 'head'] or user_role.endswith('_head')):
                return {
                    "next_status": "approved",
                    "notify_roles": [],
                    "notify_message": "Form approved.",
                    "signature_field": "noted_by",
                }
            return None

        transitions = workflow.get("transitions", {})
        config = transitions.get(current_status)

        if not config:
            # Backward compatibility: older submissions may still be stored as
            # 'pending_review' even if the workflow's real initial step is
            # 'pending_supervisor' / 'pending_multi_approval', etc.
            # Treat 'pending_review' as an alias for the workflow's initial status.
            if current_status == "pending_review":
                initial_status = WorkflowEngine.get_initial_status(template_type)
                if initial_status and initial_status != "pending_review":
                    config = transitions.get(initial_status)

        if not config:
            return None

        # Check Role Requirements
        allowed_roles = config.get("required_roles", [])
        
        role_authorized = user_role in allowed_roles
        
        if not role_authorized:
            logger.warning(f"User role '{user_role}' not authorized for transition from '{current_status}' in '{template_type}'")
            return None

        return {
            "next_status": config.get("next_status"),
            "notify_roles": config.get("notify_roles", []),
            "notify_message": config.get("notify_message", ""),
            "signature_field": config.get("signature_field", "noted_by"),
            "is_parallel": workflow.get("parallel", False),
            "parallel_roles": workflow.get("parallel_roles", []),
        }
