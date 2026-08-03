with Ada.Text_IO;

with Project_Tools.Tree_Checks;

package body Awk_Workflow_Build_Output is
   package Tree_Checks renames Project_Tools.Tree_Checks;

   procedure Run is
   begin
      Tree_Checks.Require_No_Nonempty_Stderr ("../obj", Quiet => True);
      Tree_Checks.Require_No_Nonempty_Stderr ("obj", Quiet => True);
      Ada.Text_IO.Put_Line ("build output policy checks passed");
   end Run;
end Awk_Workflow_Build_Output;
