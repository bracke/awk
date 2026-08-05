with Project_Tools.Files;

package body Awk_Workflow_Docs.Workflow_Checks.Architecture_Docs is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../docs/final-acceptance.md", "<!-- generated:awk-acceptance -->",
         "final acceptance and traceability docs must describe release gates",
         Quiet => True);
      Files.Require_Contains
        ("../docs/final-acceptance.md", "Normative acceptance gates",
         "final acceptance and traceability docs must describe release gates",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/traceability.md", "| 49 | Definition of done |",
         "final acceptance and traceability docs must describe release gates",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md",
         "only production package that directly depends on" & ASCII.LF &
         "  `hostkit`",
         "architecture docs must describe hostkit platform boundary",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/package-contracts.md",
         "Only `Awk_CLI.Platform` may call `hostkit`.",
         "architecture docs must describe hostkit platform boundary",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/package-contracts.md",
         "Only `Awk_CLI.Platform` may enumerate process-global environment variables",
         "architecture docs must describe process environment boundary",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/traceability.md", "| 1 | Project identity |",
         "traceability docs must map project identity", Quiet => True);
      Files.Require_Contains
        ("../docs/ai/traceability.md", "| 13 | Execution adapter |",
         "traceability docs must map execution adapter", Quiet => True);
      Files.Require_Contains
        ("../docs/ai/project-map.md", "Awk_CLI.Invocation",
         "project map must mention parsed invocation executor", Quiet => True);
      Files.Require_Contains
        ("../docs/ai/project-map.md", "Awk_CLI.Testing",
         "project map must mention in-memory context controls", Quiet => True);
      Files.Require_Contains
        ("../docs/ai/package-contracts.md", "Awk_CLI.Testing",
         "package contracts must mention testing context boundary", Quiet => True);
      Files.Require_Contains
        ("../docs/ai/traceability.md", "| 39 | Tooling requirements |",
         "traceability docs must map tooling requirements", Quiet => True);
      Files.Require_Contains
        ("../docs/ai/traceability.md", "| 49 | Definition of done |",
         "traceability docs must map definition of done", Quiet => True);
   end Run;
end Awk_Workflow_Docs.Workflow_Checks.Architecture_Docs;
