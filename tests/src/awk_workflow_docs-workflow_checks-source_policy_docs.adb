with Project_Tools.Files;

package body Awk_Workflow_Docs.Workflow_Checks.Source_Policy_Docs is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../docs/ai/workflows.md", "parsed" & ASCII.LF & "Ada `with` clauses",
         "AI workflow docs must mention parsed Ada source-policy validation",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/workflows.md",
         "expected local" & ASCII.LF & "Alire workspace pins",
         "AI workflow docs must mention workspace pin validation", Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md",
         "production source while allowing the diagnostic" & ASCII.LF &
         "sanitizer to recognize ESC",
         "workflow docs must describe production-wide ANSI source policy",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/workflows.md",
         "no handwritten ANSI code tokens in production source",
         "workflow docs must describe production-wide ANSI source policy",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/workflows.md", "diagnostic ESC recognition for escaping",
         "workflow docs must describe production-wide ANSI source policy",
         Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md",
         "command-line access stays in the main" & ASCII.LF &
         "containment boundary or platform adapter",
         "workflow docs must describe process-boundary source policy",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/workflows.md",
         "command-line access confined to main containment" & ASCII.LF &
         "or the platform adapter",
         "workflow docs must describe process-boundary source policy",
         Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md",
         "rejects direct `GNAT.OS_Lib`," & ASCII.LF &
         "`GNAT.Expect`, and `/bin/sh` production use in favor of `hostkit`",
         "workflow docs must describe process-boundary source policy",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/workflows.md",
         "direct `GNAT.OS_Lib`, `GNAT.Expect`, and `/bin/sh`" & ASCII.LF &
         "production use rejected in favor of `hostkit`",
         "workflow docs must describe process-boundary source policy",
         Quiet => True);
   end Run;
end Awk_Workflow_Docs.Workflow_Checks.Source_Policy_Docs;
