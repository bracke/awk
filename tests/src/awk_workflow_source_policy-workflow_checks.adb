with Awk_Workflow_Source_Policy.Workflow_Checks.CI_Release;
with Awk_Workflow_Source_Policy.Workflow_Checks.Delegation;
with Awk_Workflow_Source_Policy.Workflow_Checks.Fixtures;
with Awk_Workflow_Source_Policy.Workflow_Checks.No_Scripts;
with Awk_Workflow_Source_Policy.Workflow_Checks.Process_Tooling;

package body Awk_Workflow_Source_Policy.Workflow_Checks is

   procedure Run is
   begin
      Awk_Workflow_Source_Policy.Workflow_Checks.Process_Tooling.Run;
      Awk_Workflow_Source_Policy.Workflow_Checks.Fixtures.Run;
      Awk_Workflow_Source_Policy.Workflow_Checks.Delegation.Run;
      Awk_Workflow_Source_Policy.Workflow_Checks.CI_Release.Run;
      Awk_Workflow_Source_Policy.Workflow_Checks.No_Scripts.Run;
   end Run;

end Awk_Workflow_Source_Policy.Workflow_Checks;
