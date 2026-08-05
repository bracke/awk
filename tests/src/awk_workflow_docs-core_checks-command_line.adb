with Project_Tools.Files;

package body Awk_Workflow_Docs.Core_Checks.Command_Line is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../docs/command-line-reference.md", "-f program-file",
         "command-line reference must document program-file invocation",
         Quiet => True);
      Files.Require_Contains
        ("../docs/command-line-reference.md", "Runtime assignment operands",
         "command-line reference must document runtime assignment operands",
         Quiet => True);
      Files.Require_Contains
        ("../docs/command-line-reference.md",
         "Supports_Positional_Runtime_Assignments = True",
         "command-line reference must document positional assignment capability",
         Quiet => True);
   end Run;
end Awk_Workflow_Docs.Core_Checks.Command_Line;
