with Project_Tools.Files;

package body Awk_Workflow_Docs.Workflow_Checks.Testing_Docs is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../docs/testing.md", "structured diagnostic",
         "testing docs must mention structured diagnostic assertions",
         Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md", "conformance manifest",
         "testing docs must mention conformance manifest validation",
         Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md", "Alire install-boundary",
         "testing docs must mention install-boundary validation", Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md", "checks local Alire workspace pins",
         "testing docs must mention workspace pin validation", Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md", "parsed Ada `with` clauses",
         "testing docs must mention parsed Ada source-policy validation",
         Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md", "FNV-1a-64",
         "testing docs must mention release checksum validation", Quiet => True);
      Files.Require_Contains
        ("../docs/building.md", "install boundary",
         "building docs must mention install boundary verification",
         Quiet => True);
      Files.Require_Contains
        ("../docs/building.md", "generated release packages",
         "building docs must mention generated release package cleanup",
         Quiet => True);
      Files.Require_Contains
        ("../docs/building.md", "local Alire workspace pins",
         "building docs must mention workspace pin verification", Quiet => True);
   end Run;
end Awk_Workflow_Docs.Workflow_Checks.Testing_Docs;
