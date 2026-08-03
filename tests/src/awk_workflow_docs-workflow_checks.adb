with Project_Tools.Files;

package body Awk_Workflow_Docs.Workflow_Checks is
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
      Files.Require_Contains
        ("../docs/releasing.md", "--release --profiles=*=release",
         "release docs must document release-profile builds", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "clean git working tree",
         "release docs must document clean-tree enforcement", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "local Alire workspace pins",
         "release docs must mention workspace pin verification", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "FNV-1a-64",
         "release docs must document manifest checksum algorithm", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "dependency policy",
         "release docs must document packaged audit documentation", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "traceability matrix",
         "release docs must document packaged audit documentation", Quiet => True);
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
        ("../docs/releasing.md",
         "`terminal_styles = ""=0.1.0-dev""` and `hostkit = ""=0.1.0-dev""`",
         "release traceability docs must mention current dev dependency constraints",
         Quiet => True);
      Files.Require_Contains
        ("../docs/ai/traceability.md",
         "`terminal_styles = ""=0.1.0-dev""` and" & ASCII.LF &
         "`hostkit = ""=0.1.0-dev""`",
         "release traceability docs must mention current dev dependency constraints",
         Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "temporary prefix",
         "release docs must document temporary install-prefix validation",
         Quiet => True);
      Files.Require_Contains
        ("../docs/dependency-policy.md", "workspace release model",
         "dependency policy must document workspace release model", Quiet => True);
      Files.Require_Contains
        ("../docs/dependency-policy.md",
         "No direct dependency may use an unrestricted wildcard",
         "dependency policy must reject wildcard release constraints",
         Quiet => True);
      Files.Require_Contains
        ("../docs/dependency-policy.md", "Publish readiness is a separate gate",
         "dependency policy must document publish readiness separation",
         Quiet => True);
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
end Awk_Workflow_Docs.Workflow_Checks;
