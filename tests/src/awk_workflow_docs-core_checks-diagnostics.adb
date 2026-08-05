with Project_Tools.Files;

package body Awk_Workflow_Docs.Core_Checks.Diagnostics is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../docs/diagnostics.md", "destination-aware terminal detection",
         "diagnostics docs must document destination-aware terminal styling",
         Quiet => True);
      Files.Require_Contains
        ("../docs/diagnostics.md", "open failures from read failures",
         "diagnostics docs must document open/read failure distinction",
         Quiet => True);
   end Run;
end Awk_Workflow_Docs.Core_Checks.Diagnostics;
