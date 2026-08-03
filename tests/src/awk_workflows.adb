with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Awk_Workflow_Catalogs;
with Awk_Workflow_Packaging;
with Awk_Workflow_Source_Policy;
with Project_Tools.Alire;
with Project_Tools.Alire_Manifests.Validation;
with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Test_Fixtures;
with Project_Tools.Text;
with Project_Tools.TOML;
with Project_Tools.Tree_Checks;

procedure Awk_Workflows is
   package CLI renames Ada.Command_Line;
   package Manifests renames Project_Tools.Alire_Manifests.Validation;
   package Proc renames Project_Tools.Processes;
   package Files renames Project_Tools.Files;
   package Fixtures renames Project_Tools.Test_Fixtures;
   package Text renames Project_Tools.Text;
   package TOML renames Project_Tools.TOML;
   package Tree_Checks renames Project_Tools.Tree_Checks;
   package U renames Ada.Strings.Unbounded;

   Root : constant String := "..";
   No_Arguments : constant GNAT.OS_Lib.Argument_List (1 .. 0) := [];

   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Fail (Message : String) is
   begin
      Project_Tools.Release_Checks.Fail (Message);
   end Fail;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Fail (Message);
      end if;
   end Require;

   procedure Build is
   begin
      Project_Tools.Alire.Run_Build (Directory => Root);
      Project_Tools.Alire.Run_Build (Directory => ".");
   end Build;

   procedure Test is
   begin
      Project_Tools.Alire.Run_Build (Directory => ".");
      Project_Tools.Release_Checks.Run
        ("./bin/awk_tests_main", ".", "./bin/awk_tests_main", No_Arguments);
   end Test;

   procedure Require_Clean_Repository is
   begin
      Project_Tools.Release_Checks.Require_Clean_Git_Worktree
        ("awk", Root, Quiet => True);
   end Require_Clean_Repository;

   procedure Docs is
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
   end Docs;

   procedure Metadata is
      Root_Alire  : constant String := Fixtures.Read_Text_File ("../alire.toml");
      Tests_Alire : constant String := Fixtures.Read_Text_File ("alire.toml");
      Root_Version : constant String :=
        TOML.String_Value_After (Root_Alire, "version =", Root_Alire'First);
      Tests_Version : constant String :=
        TOML.String_Value_After (Tests_Alire, "version =", Tests_Alire'First);
      Awklib_Constraint : constant String :=
        TOML.String_Value_After (Root_Alire, "awklib =", Root_Alire'First);

      function Constraint_Version (Constraint : String) return String is
      begin
         if Constraint'Length > 0
           and then (Constraint (Constraint'First) = '~'
                     or else Constraint (Constraint'First) = '=')
         then
            return Constraint (Constraint'First + 1 .. Constraint'Last);
         else
            return Constraint;
         end if;
      end Constraint_Version;

      Awklib_Version : constant String := Constraint_Version (Awklib_Constraint);
   begin
      Require (TOML.String_Value_After (Root_Alire, "name =", Root_Alire'First) = "awk",
               "root crate name must be awk");
      Require (Root_Version /= "", "root crate version must be declared");
      Require (Tests_Version = Root_Version,
               "tests crate version must match root crate version");
      Require (Awklib_Version /= "", "awklib dependency version must be declared");
      Files.Require_Contains
        ("../config/awk_config.ads",
         "Crate_Version : constant String := """ & Root_Version & """",
         "generated Ada config must match root crate version", Quiet => True);
      Files.Require_Contains
        ("../config/awk_config.gpr",
         "Crate_Version := """ & Root_Version & """",
         "generated GPR config must match root crate version", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "dist/awk-" & Root_Version,
         "release docs must document the current package directory",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-compatibility.adb",
         "resolved awklib " & Awklib_Version & " behavior",
         "compatibility registry must document the current awklib version",
         Quiet => True);
      Files.Require_Contains
        ("../docs/compatibility.md",
         "resolved awklib " & Awklib_Version & " behavior",
         "compatibility docs must document the current awklib version",
         Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "executables = [""awk""]",
         "root crate must install executable awk", Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "project-files = [""awk.gpr""]",
         "root crate must use awk.gpr", Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "awklib = ",
         "root crate must depend on awklib", Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "terminal_styles = ",
         "root crate must depend on terminal_styles", Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "messages = ",
         "root crate must depend on messages", Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "hostkit = ",
         "root crate must depend on hostkit", Quiet => True);
      Require (not Text.Contains (Root_Alire, "awklib = ""*"""),
               "root awklib dependency must not use wildcard constraint");
      Require (not Text.Contains (Root_Alire, "terminal_styles = ""*"""),
               "root terminal_styles dependency must not use wildcard constraint");
      Require (not Text.Contains (Root_Alire, "messages = ""*"""),
               "root messages dependency must not use wildcard constraint");
      Require (not Text.Contains (Root_Alire, "hostkit = ""*"""),
               "root hostkit dependency must not use wildcard constraint");
      Files.Require_Contains
        ("../docs/dependency-policy.md", "terminal_styles = ""=0.1.0-dev""",
         "dependency policy must document the current terminal_styles dev constraint",
         Quiet => True);
      Files.Require_Contains
        ("../docs/dependency-policy.md", "hostkit = ""=0.1.0-dev""",
         "dependency policy must document the current hostkit dev constraint",
         Quiet => True);
      Files.Require_Contains
        ("../docs/dependency-policy.md",
         "| `messages` | `~0.1.0` | `../../messages` |",
         "dependency policy must document the tests messages dependency",
         Quiet => True);
      Require (TOML.String_Value_After (Tests_Alire, "name =", Tests_Alire'First) = "awk_tests",
               "tests crate name must be awk_tests");
      Files.Require_Contains
        ("alire.toml", "executables = [""awk_tests_main"", ""awk_workflows""]",
         "tests crate must expose the test and workflow executables",
         Quiet => True);
      Files.Require_Contains
        ("alire.toml", "awk = ",
         "tests crate must depend on awk", Quiet => True);
      Files.Require_Contains
        ("alire.toml", "aunit = ",
         "tests crate must depend on AUnit", Quiet => True);
      Files.Require_Contains
        ("alire.toml", "project_tools = ",
         "tests crate must depend on project_tools", Quiet => True);
      Files.Require_Contains
        ("alire.toml", "messages = ",
         "tests crate must depend on messages for catalog consistency checks",
         Quiet => True);
      Files.Require_Contains
        ("alire.toml", "awk = { path = "".."" }",
         "tests crate must pin awk relatively", Quiet => True);
      Manifests.Require_Workspace_Pin ("../alire.toml", "awklib", "../awklib", Quiet => True);
      Manifests.Require_Workspace_Pin
        ("../alire.toml", "terminal_styles", "../terminal_styles", Quiet => True);
      Manifests.Require_Workspace_Pin ("../alire.toml", "messages", "../messages", Quiet => True);
      Manifests.Require_Workspace_Pin ("../alire.toml", "hostkit", "../hostkit", Quiet => True);
      Manifests.Require_Workspace_Pin ("alire.toml", "awk", "..", Quiet => True);
      Manifests.Require_Workspace_Pin
        ("alire.toml", "project_tools", "../../project_tools", Quiet => True);
      Manifests.Require_Workspace_Pin
        ("alire.toml", "messages", "../../messages", Quiet => True);
      Files.Require_Contains
        ("../awk.gpr", "-gnat2022",
         "root project must compile with Ada 2022", Quiet => True);
      Files.Require_Contains
        ("awk_tests.gpr", "-gnat2022",
         "tests project must compile with Ada 2022", Quiet => True);
      Files.Require_Contains
        ("../awk.gpr", "for Main use (""awk.adb"")",
         "root project main must be awk.adb", Quiet => True);
      Files.Require_Contains
        ("awk_tests.gpr", "awk_workflows.adb",
         "tests project must build workflow executable", Quiet => True);
      Files.Require_Contains
        ("awk_tests.gpr", "awk_tests_main.adb",
         "tests project must build AUnit executable", Quiet => True);
      Require (TOML.String_Value_After (Root_Alire, "licenses =", Root_Alire'First) = "MIT",
               "root crate must declare MIT license");
      Require (TOML.String_Value_After (Tests_Alire, "licenses =", Tests_Alire'First) = "MIT",
               "tests crate must declare MIT license");
      Put_Info ("metadata checks passed");
   end Metadata;



   procedure Conformance is
      procedure Require_Case (Id, Status, Case_File, Expected, Reference : String) is
         Line : constant String :=
           Id & "|" & Status & "|" & Case_File & "|" & Expected & "|" & Reference;
      begin
         Require (Files.Has_Line ("conformance/manifest/cases.txt", Line),
                  "conformance manifest missing case: " & Id);
         Files.Require_File
           ("conformance/" & Case_File,
            "conformance case file missing: " & Case_File);
         Files.Require_File
           ("conformance/" & Expected,
            "conformance expected file missing: " & Expected);
         Require (Project_Tools.Release_Checks.File_Length ("conformance/" & Case_File) > 0,
                  "conformance case file is empty: " & Case_File);
         Require (Project_Tools.Release_Checks.File_Length ("conformance/" & Expected) > 0,
                  "conformance expected file is empty: " & Expected);
      end Require_Case;
   begin
      Files.Require_File
        ("conformance/manifest/cases.txt",
         "conformance manifest is missing or empty");
      Require
        (Project_Tools.Release_Checks.File_Length ("conformance/manifest/cases.txt") > 0,
         "conformance manifest is missing or empty");
      Require_Case
        ("AWK-CONF-PRINT-001", "Supported", "cases/print_record.awk",
         "expected/print_record.txt", "basic print through awklib");
      Require_Case
        ("AWK-CONF-FIELDS-001", "Supported", "cases/print_first_field.awk",
         "expected/print_first_field.txt", "field processing through awklib");
      Require_Case
        ("AWK-CONF-ASSIGNMENT-001", "Supported",
         "cases/runtime_assignment.awk", "expected/runtime_assignment.txt",
         "positional runtime assignment supported");
      Require_Case
        ("AWK-CONF-REDIRECTION-001", "Supported",
         "cases/append_redirection.awk", "expected/append_redirection.txt",
         "append redirection supported through awklib streaming callbacks");
      Require_Case
        ("AWK-CONF-GETLINE-001", "Supported",
         "cases/command_getline.awk", "expected/command_getline.txt",
         "command getline supported through awklib callback");
      Put_Info ("conformance checks passed");
   end Conformance;

   function Exit_Constant_Value (Source, Name : String) return String is
      Mark : Natural := Text.Index (Source, Name);
      Scan : Natural;
      Last : Natural;
   begin
      if Mark = 0 then
         return "";
      end if;

      Mark := Text.Index_From (Source, ":=", Mark);
      if Mark = 0 then
         return "";
      end if;

      Scan := Mark + 2;
      while Scan <= Source'Last and then Source (Scan) = ' ' loop
         Scan := Scan + 1;
      end loop;

      Last := Scan - 1;
      while Last < Source'Last and then Source (Last + 1) in '0' .. '9' loop
         Last := Last + 1;
      end loop;

      if Last < Scan then
         return "";
      end if;
      return Source (Scan .. Last);
   end Exit_Constant_Value;

   procedure Exit_Status_Drift is
      Source    : constant String := Fixtures.Read_Text_File ("../src/library/awk_cli-diagnostics.ads");
      Docs      : constant String := Fixtures.Read_Text_File ("../docs/diagnostics.md");
      Reference : constant String := Fixtures.Read_Text_File ("../docs/command-line-reference.md");
      Allowed   : U.Unbounded_String;

      procedure Require_Exit (Name : String) is
         Value : constant String := Exit_Constant_Value (Source, Name);
      begin
         Require (Value /= "", "exit status constant missing from source: " & Name);
         U.Append (Allowed, " " & Value & " ");
         Require
           (Text.Contains (Docs, "| `" & Value & "` |"),
            "exit status " & Value & " from " & Name & " is not documented");
         Require
           (Text.Contains (Reference, "`" & Value & "`"),
            "exit status " & Value & " from " & Name
            & " is missing from the command-line reference");
      end Require_Exit;

      From : Positive := Docs'First;
   begin
      Require_Exit ("Success_Exit");
      Require_Exit ("Interpreter_Exit");
      Require_Exit ("Usage_Exit");
      Require_Exit ("IO_Exit");
      Require_Exit ("Internal_Exit");

      while From <= Docs'Last loop
         declare
            Mark : constant Natural := Text.Index_From (Docs, "| `", From);
            Stop : Natural;
         begin
            exit when Mark = 0;
            Stop := Mark + 3;
            while Stop <= Docs'Last and then Docs (Stop) in '0' .. '9' loop
               Stop := Stop + 1;
            end loop;
            if Stop > Mark + 3
              and then Stop <= Docs'Last
              and then Docs (Stop) = '`'
            then
               declare
                  Value : constant String := Docs (Mark + 3 .. Stop - 1);
               begin
                  Require
                    (Text.Contains (U.To_String (Allowed), " " & Value & " "),
                     "exit status " & Value & " is documented but not defined");
               end;
            end if;
            From := Mark + 3;
         end;
      end loop;
      Put_Info ("exit status drift checks passed");
   end Exit_Status_Drift;

   procedure Option_Drift is
      procedure Require_Option (Spelling : String) is
      begin
         Files.Require_Contains
           ("../docs/command-line-reference.md", Spelling,
            "command-line reference missing accepted option: " & Spelling,
            Quiet => True);
         Files.Require_Contains
           ("../resources/messages/catalog.txt", Spelling,
            "help catalog missing accepted option: " & Spelling,
            Quiet => True);
      end Require_Option;
   begin
      Require_Option ("-F");
      Require_Option ("-v");
      Require_Option ("-f");
      Require_Option ("--color");
      Require_Option ("--help");
      Require_Option ("--version");
      Require_Option ("--");
      Files.Require_Contains
        ("../docs/command-line-reference.md", "--color=auto|always|never",
         "color modes must stay documented in reference and help catalog",
         Quiet => True);
      Files.Require_Contains
        ("../resources/messages/catalog.txt", "--color=auto|always|never",
         "color modes must stay documented in reference and help catalog",
         Quiet => True);
      Files.Require_Contains
        ("../docs/quickstart.md", "awk '{ print $1 }'",
         "quickstart must document direct, -F, and -f invocation examples",
         Quiet => True);
      Files.Require_Contains
        ("../docs/quickstart.md", "awk -F:",
         "quickstart must document direct, -F, and -f invocation examples",
         Quiet => True);
      Files.Require_Contains
        ("../docs/quickstart.md", "awk -f script.awk",
         "quickstart must document direct, -F, and -f invocation examples",
         Quiet => True);
      Put_Info ("option drift checks passed");
   end Option_Drift;



   procedure Install_Boundary is
      Prefix : constant String := Files.Join (Files.Temp_Dir, "awk-install-boundary");
      Output : Proc.Unbounded_String;
      Install_Args : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("-n"),
         new String'("install"),
         new String'("--prefix=" & Prefix)];
      Version_Args : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--version")];
   begin
      Proc.Require_Command ("alr", "alr executable not found", Quiet => True);
      Files.Delete_Tree (Prefix);

      declare
         Alr : constant String := Proc.Locate_Command ("alr");
      begin
         Proc.Run ("alr install", Root, Alr, Install_Args, Quiet => True);
      end;

      Files.Require_File (Prefix & "/bin/awk", "installed awk executable missing");
      Proc.Run
        ("installed awk --version", Root, Prefix & "/bin/awk", Version_Args,
         Output, Quiet => True);
      Require (Text.Contains (U.To_String (Output), "awk 0.1.0"),
               "installed awk version output is unexpected");

      Files.Delete_Tree (Prefix);
      Put_Info ("install boundary checks passed");
   end Install_Boundary;

   procedure Build_Output_Policy is
   begin
      Tree_Checks.Require_No_Nonempty_Stderr ("../obj", Quiet => True);
      Tree_Checks.Require_No_Nonempty_Stderr ("obj", Quiet => True);
      Put_Info ("build output policy checks passed");
   end Build_Output_Policy;

   procedure Verify is
   begin
      Build;
      Test;
      Metadata;
      Docs;
      Awk_Workflow_Catalogs.Run;
      Conformance;
      Exit_Status_Drift;
      Option_Drift;
      Awk_Workflow_Source_Policy.Package_Manifest_Policy;
      Awk_Workflow_Source_Policy.Run;
      Install_Boundary;
      Build_Output_Policy;
   end Verify;

   procedure Clean is
   begin
      Files.Delete_Tree ("../obj");
      Files.Delete_Tree ("../bin");
      Files.Delete_Tree ("../dist");
      Files.Delete_Tree ("obj");
      Files.Delete_Tree ("bin");
      Put_Info ("cleaned build outputs");
   end Clean;


   procedure Usage is
   begin
      Ada.Text_IO.Put_Line
        ("usage: awk_workflows build|test|verify|docs|clean|package|release");
   end Usage;

   Command : constant String := (if CLI.Argument_Count = 0 then "verify" else CLI.Argument (1));
begin
   if Command = "build" then
      Build;
      Build_Output_Policy;
   elsif Command = "test" then
      Test;
      Build_Output_Policy;
   elsif Command = "verify" then
      Verify;
   elsif Command = "docs" then
      Docs;
   elsif Command = "clean" then
      Clean;
   elsif Command = "package" then
      Awk_Workflow_Packaging.Run;
      Build_Output_Policy;
   elsif Command = "release" then
      Require_Clean_Repository;
      Project_Tools.Alire.Run_Build (Directory => Root, Release_Mode => True);
      Project_Tools.Alire.Run_Build (Directory => ".", Release_Mode => True);
      Project_Tools.Release_Checks.Run
        ("./bin/awk_tests_main", ".", "./bin/awk_tests_main", No_Arguments);
      Metadata;
      Docs;
      Awk_Workflow_Catalogs.Run;
      Conformance;
      Awk_Workflow_Source_Policy.Run;
      Exit_Status_Drift;
      Option_Drift;
      Awk_Workflow_Source_Policy.Package_Manifest_Policy;
      Install_Boundary;
      Awk_Workflow_Packaging.Run (Release_Mode => True);
      Build_Output_Policy;
   elsif Command = "--help" or else Command = "-h" then
      Usage;
   else
      Usage;
      CLI.Set_Exit_Status (CLI.Failure);
   end if;
exception
   when Program_Error =>
      null;
   when Error : others =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "unexpected workflow failure: " & Ada.Exceptions.Exception_Information (Error));
      CLI.Set_Exit_Status (CLI.Failure);
end Awk_Workflows;
