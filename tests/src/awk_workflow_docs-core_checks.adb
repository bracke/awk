with Ada.Strings.Unbounded;

with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Docs.Core_Checks is
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

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
end Awk_Workflow_Docs.Core_Checks;
