with Awk_Workflow_Docs.Workflow_Checks.Architecture_Docs;
with Awk_Workflow_Docs.Workflow_Checks.Release_Docs;
with Awk_Workflow_Docs.Workflow_Checks.Source_Policy_Docs;
with Awk_Workflow_Docs.Workflow_Checks.Testing_Docs;

package body Awk_Workflow_Docs.Workflow_Checks is
   procedure Run is
   begin
      Awk_Workflow_Docs.Workflow_Checks.Testing_Docs.Run;
      Awk_Workflow_Docs.Workflow_Checks.Release_Docs.Run;
      Awk_Workflow_Docs.Workflow_Checks.Source_Policy_Docs.Run;
      Awk_Workflow_Docs.Workflow_Checks.Architecture_Docs.Run;
   end Run;
end Awk_Workflow_Docs.Workflow_Checks;
