with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Docs is
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Run is
      Required_Docs : constant Files.Path_List :=
        [U.To_Unbounded_String ("../README.md"),
         U.To_Unbounded_String ("../CHANGELOG.md"),
         U.To_Unbounded_String ("../CONTRIBUTING.md"),
         U.To_Unbounded_String ("../SECURITY.md"),
         U.To_Unbounded_String ("../LICENSE"),
         U.To_Unbounded_String ("../docs/quickstart.md"),
         U.To_Unbounded_String ("../docs/command-line-reference.md"),
         U.To_Unbounded_String ("../docs/compatibility.md"),
         U.To_Unbounded_String ("../docs/architecture.md"),
         U.To_Unbounded_String ("../docs/diagnostics.md"),
         U.To_Unbounded_String ("../docs/localization.md"),
         U.To_Unbounded_String ("../docs/localization-reference.md"),
         U.To_Unbounded_String ("../docs/testing.md"),
         U.To_Unbounded_String ("../docs/building.md"),
         U.To_Unbounded_String ("../docs/releasing.md"),
         U.To_Unbounded_String ("../docs/dependency-policy.md"),
         U.To_Unbounded_String ("../docs/final-acceptance.md"),
         U.To_Unbounded_String ("../docs/ai/project-map.md"),
         U.To_Unbounded_String ("../docs/ai/package-contracts.md"),
         U.To_Unbounded_String ("../docs/ai/invariants.md"),
         U.To_Unbounded_String ("../docs/ai/workflows.md"),
         U.To_Unbounded_String ("../docs/ai/prohibited-designs.md"),
         U.To_Unbounded_String ("../docs/ai/traceability.md")];
      Stale_Docs : constant String :=
        Project_Tools.Release_Checks.Stale_Doc_Scaffolding ("..");
   begin
      Files.Require_Files (Required_Docs, "missing required documentation");
      Require
        (Stale_Docs = "",
         "documentation contains stale scaffolding language: " & Stale_Docs);
      Files.Require_Contains
        ("../README.md", "does not claim complete POSIX conformance",
         "README must not claim full POSIX conformance", Quiet => True);
      Files.Require_Contains
        ("../README.md", "./bin/awk_tests_main",
         "README must document the current AUnit executable", Quiet => True);
      Files.Require_Contains
        ("../README.md", "--color=auto|always|never",
         "README must document color policy", Quiet => True);
      Files.Require_Contains
        ("../README.md", "Windows",
         "README must include Windows quoting guidance", Quiet => True);
      Files.Require_Contains
        ("../LICENSE", "MIT License",
         "LICENSE must contain MIT license text", Quiet => True);
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
      Files.Require_Contains
        ("../docs/architecture.md", "Awk_CLI.Execution",
         "architecture docs must document execution adapter isolation",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md", "Invocation_Context",
         "architecture docs must document testable invocation context",
         Quiet => True);
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
      Files.Require_Contains
        ("../docs/diagnostics.md", "destination-aware terminal detection",
         "diagnostics docs must document destination-aware terminal styling",
         Quiet => True);
      Files.Require_Contains
        ("../docs/diagnostics.md", "open failures from read failures",
         "diagnostics docs must document open/read failure distinction",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md",
         "only production package that directly depends on" & ASCII.LF &
         "  `hostkit`",
         "platform docs must document the hostkit adapter boundary",
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
        ("../docs/localization.md", "awk.internal.localization_failed",
         "localization docs must document catalog-backed render fallback",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization.md", "last-resort containment",
         "localization docs must document catalog-backed render fallback",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization.md", "English fallback help and diagnostic",
         "localization docs must document help and diagnostic fallback checks",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization.md", "localized CLI text",
         "localization docs must document help and diagnostic fallback checks",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization.md", "Localization Reference",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "POSIX `awk` utility text",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "GNU awk",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "BWK awk",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "BusyBox awk",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "Reference run record",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "/usr/bin/mawk -W help",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "/usr/bin/busybox awk --help",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "Reference comparison checklist",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization-reference.md", "Machine-checked reference cues",
         "localization docs must require comparison with other AWK reference text",
         Quiet => True);
      Files.Require_Contains
        ("../docs/localization.md", "supported European state-language locale set",
         "localization docs must document supported European locale catalog validation",
         Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md",
         "every supported European" & ASCII.LF & "state-language locale",
         "localization docs must document supported European locale catalog validation",
         Quiet => True);
      Files.Require_Contains
        ("../docs/architecture.md", "main input is callback-driven",
         "architecture docs must document memory-oriented host integration",
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
        ("../docs/ai/traceability.md", "| 1 | Project identity |",
         "traceability docs must map project identity", Quiet => True);
      Files.Require_Contains
        ("../docs/ai/traceability.md", "| 13 | Execution adapter |",
         "traceability docs must map execution adapter", Quiet => True);
      Files.Require_Contains
        ("../docs/ai/traceability.md", "| 39 | Tooling requirements |",
         "traceability docs must map tooling requirements", Quiet => True);
      Files.Require_Contains
        ("../docs/ai/traceability.md", "| 49 | Definition of done |",
         "traceability docs must map definition of done", Quiet => True);
      Put_Info ("documentation checks passed");
   end Run;
end Awk_Workflow_Docs;
