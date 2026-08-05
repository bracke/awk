with Awk_Workflow_Source_Policy.Platform_Checks.Command_File_Contracts;
with Awk_Workflow_Source_Policy.Platform_Checks.Platform_Structure;
with Awk_Workflow_Source_Policy.Platform_Checks.Prohibited_APIs;
with Awk_Workflow_Source_Policy.Platform_Checks.Stream_Contracts;

package body Awk_Workflow_Source_Policy.Platform_Checks is
   procedure Run is
   begin
      Awk_Workflow_Source_Policy.Platform_Checks.Prohibited_APIs.Run;
      Awk_Workflow_Source_Policy.Platform_Checks.Stream_Contracts.Run;
      Awk_Workflow_Source_Policy.Platform_Checks.Platform_Structure.Run;
      Awk_Workflow_Source_Policy.Platform_Checks.Command_File_Contracts.Run;
   end Run;
end Awk_Workflow_Source_Policy.Platform_Checks;
