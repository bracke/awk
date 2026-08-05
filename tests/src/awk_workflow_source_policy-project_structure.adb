with Awk_Workflow_Source_Policy.Project_Structure.Context_Contracts;
with Awk_Workflow_Source_Policy.Project_Structure.Delegation_Checks;
with Awk_Workflow_Source_Policy.Project_Structure.Execution_Contracts;
with Awk_Workflow_Source_Policy.Project_Structure.Inventory_Checks;

package body Awk_Workflow_Source_Policy.Project_Structure is
   procedure Run is
   begin
      Awk_Workflow_Source_Policy.Project_Structure.Delegation_Checks.Run;
      Awk_Workflow_Source_Policy.Project_Structure.Inventory_Checks.Run;
      Awk_Workflow_Source_Policy.Project_Structure.Context_Contracts.Run;
      Awk_Workflow_Source_Policy.Project_Structure.Execution_Contracts.Run;
   end Run;
end Awk_Workflow_Source_Policy.Project_Structure;
