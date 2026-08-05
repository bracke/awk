with Project_Tools.Files;

package body Awk_Workflow_Docs.Core_Checks.Compatibility is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../docs/compatibility.md",
         "No current entries are classified as unsupported",
         "compatibility docs must state the active limitation position",
         Quiet => True);
      Files.Require_Contains
        ("../docs/compatibility.md", "AWK-COMPAT-GETLINE-002",
         "compatibility docs must include reviewed compatibility IDs",
         Quiet => True);
      Files.Require_Contains
        ("../docs/compatibility.md", "Test reference",
         "compatibility docs must include test references", Quiet => True);
      Files.Require_Contains
        ("../docs/compatibility.md", "Status",
         "compatibility docs must include status names", Quiet => True);
      Files.Require_Contains
        ("../docs/compatibility.md", "Source",
         "compatibility docs must include limitation source", Quiet => True);
   end Run;
end Awk_Workflow_Docs.Core_Checks.Compatibility;
