with Project_Tools.Files;

package body Awk_Workflow_Docs.Core_Checks.Architecture is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../docs/architecture.md", "Awk_CLI.Execution",
         "architecture docs must document execution adapter isolation",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md", "Awk_CLI.Invocation",
         "architecture docs must document parsed invocation executor",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md", "Invocation_Context",
         "architecture docs must document testable invocation context",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md", "Awk_CLI.Testing",
         "architecture docs must document in-memory context controls",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md",
         "only production package that directly depends on" & ASCII.LF &
         "  `hostkit`",
         "platform docs must document the hostkit adapter boundary",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md", "process environment enumeration",
         "platform docs must document process environment enumeration boundary",
         Quiet => True);
      Files.Require_Contains
        ("../docs/dependency-policy.md", "Platform-access dependency",
         "platform docs must document the hostkit adapter boundary",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/package-contracts.md",
         "Only `Awk_CLI.Platform` may call `hostkit`",
         "platform docs must document the hostkit adapter boundary",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/package-contracts.md",
         "`command | getline` is an awklib-owned runtime feature",
         "package contracts must define command getline callback ownership",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/prohibited-designs.md",
         "only permitted host shell use is the `command | getline` service",
         "prohibited-design docs must distinguish command getline from fallbacks",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md", "main input is callback-driven",
         "architecture docs must document memory-oriented host integration",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md",
         "The command-execution path is not an AWK fallback",
         "architecture docs must define command getline callback ownership",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md", "AWK record splitting",
         "architecture docs must document awklib text streaming callbacks",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md", "Supports_Redirection_Append_Mode = True",
         "architecture docs must document append redirection capability",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md", "Supports_Streaming_Execution = True",
         "architecture docs must document streaming capability", Quiet => True);
   end Run;
end Awk_Workflow_Docs.Core_Checks.Architecture;
