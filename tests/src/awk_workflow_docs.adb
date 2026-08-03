with Ada.Text_IO;

with Awk_Workflow_Docs.Core_Checks;
with Awk_Workflow_Docs.Workflow_Checks;

package body Awk_Workflow_Docs is
   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Run is
   begin
      Awk_Workflow_Docs.Core_Checks.Run;
      Awk_Workflow_Docs.Workflow_Checks.Run;
      Put_Info ("documentation checks passed");
   end Run;
end Awk_Workflow_Docs;
