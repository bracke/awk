with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Awk_Catalog_Policy;
with Messages.Consistency;
with Project_Tools.Alire;
with Project_Tools.Alire_Manifests.Validation;
with Project_Tools.Ada_Source;
with Project_Tools.AUnit_Checks;
with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Test_Fixtures;
with Project_Tools.Text;
with Project_Tools.TOML;
with Project_Tools.Tree_Checks;

procedure Awk_Workflows is
   package CLI renames Ada.Command_Line;
   package Dir renames Ada.Directories;
   package Ada_Source renames Project_Tools.Ada_Source;
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

   Package_Files : constant Files.Path_List :=
     [U.To_Unbounded_String ("bin/awk"),
      U.To_Unbounded_String ("LICENSE"),
      U.To_Unbounded_String ("README.md"),
      U.To_Unbounded_String ("CHANGELOG.md"),
      U.To_Unbounded_String ("CONTRIBUTING.md"),
      U.To_Unbounded_String ("SECURITY.md"),
      U.To_Unbounded_String ("docs/quickstart.md"),
      U.To_Unbounded_String ("docs/command-line-reference.md"),
      U.To_Unbounded_String ("docs/compatibility.md"),
      U.To_Unbounded_String ("docs/architecture.md"),
      U.To_Unbounded_String ("docs/diagnostics.md"),
      U.To_Unbounded_String ("docs/localization.md"),
      U.To_Unbounded_String ("docs/localization-reference.md"),
      U.To_Unbounded_String ("docs/testing.md"),
      U.To_Unbounded_String ("docs/building.md"),
      U.To_Unbounded_String ("docs/releasing.md"),
      U.To_Unbounded_String ("docs/dependency-policy.md"),
      U.To_Unbounded_String ("docs/final-acceptance.md"),
      U.To_Unbounded_String ("docs/ai/project-map.md"),
      U.To_Unbounded_String ("docs/ai/package-contracts.md"),
      U.To_Unbounded_String ("docs/ai/invariants.md"),
      U.To_Unbounded_String ("docs/ai/workflows.md"),
      U.To_Unbounded_String ("docs/ai/prohibited-designs.md"),
      U.To_Unbounded_String ("docs/ai/traceability.md"),
      U.To_Unbounded_String ("resources/messages/catalog.txt"),
      U.To_Unbounded_String ("resources/messages/en/catalog.txt"),
      U.To_Unbounded_String ("resources/messages/da/catalog.txt")];

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

   procedure Catalogs is
      Catalog    : constant String := Fixtures.Read_Text_File ("../resources/messages/catalog.txt");
      English    : constant String := Fixtures.Read_Text_File ("../resources/messages/en/catalog.txt");
      Danish     : constant String := Fixtures.Read_Text_File ("../resources/messages/da/catalog.txt");

      procedure Require_Key (Key : String) is
      begin
         Require (Text.Contains (Catalog, Key & " ="), "message catalog missing key: " & Key);
         Require (Text.Line_Value (Catalog, Key) /= "",
                  "message catalog has empty key: " & Key);
      end Require_Key;

      procedure Require_Shard_Key (Shard, Key, Name : String) is
      begin
         Require (Text.Contains (Shard, Key & " ="),
                  Name & " catalog shard missing key: " & Key);
         Require (Text.Line_Value (Shard, Key) /= "",
                  Name & " catalog shard has empty key: " & Key);
      end Require_Shard_Key;

      procedure Require_Consistent_Translations is
         Tokens : constant Messages.Consistency.Token_Array :=
           [U.To_Unbounded_String ("awk"),
            U.To_Unbounded_String ("awklib"),
            U.To_Unbounded_String ("-F"),
            U.To_Unbounded_String ("-v"),
            U.To_Unbounded_String ("-f"),
            U.To_Unbounded_String ("--help"),
            U.To_Unbounded_String ("--version"),
            U.To_Unbounded_String ("--color"),
            U.To_Unbounded_String ("--"),
            U.To_Unbounded_String ("ARGV"),
            U.To_Unbounded_String ("ARGC"),
            U.To_Unbounded_String ("ENVIRON"),
            U.To_Unbounded_String ("BEGIN"),
            U.To_Unbounded_String ("END"),
            U.To_Unbounded_String ("getline"),
            U.To_Unbounded_String ("print"),
            U.To_Unbounded_String ("printf"),
            U.To_Unbounded_String ("POSIX"),
            U.To_Unbounded_String ("MIT")];
         Findings : Messages.Consistency.Report;
      begin
         Messages.Consistency.Check_File
           (Path     => "../resources/messages/catalog.txt",
            Verbatim => Tokens,
            Into     => Findings);

         for Index in 1 .. Findings.Count loop
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               ("translation consistency finding: "
                & Messages.Consistency.Image (Findings.Items (Index))));
         end loop;

         Require
           (Findings.Count = 0,
            "translation consistency check reported findings");

         Require
           (not Findings.Overflow,
            "translation consistency produced more findings than the report holds");
      end Require_Consistent_Translations;

      procedure Require_No_English_Help_Fallbacks is
         Banned : constant array (Positive range <>) of U.Unbounded_String :=
           [U.To_Unbounded_String ("Ada command-line AWK implementation"),
            U.To_Unbounded_String ("Operands after the program are named input files"),
            U.To_Unbounded_String ("If no input operand is present"),
            U.To_Unbounded_String ("Exit statuses: 0 success"),
            U.To_Unbounded_String ("This program does not claim complete POSIX conformance"),
            U.To_Unbounded_String ("getline behavior follows awklib."),
            U.To_Unbounded_String ("set FS before execution"),
            U.To_Unbounded_String ("final occurrence wins"),
            U.To_Unbounded_String ("assign a variable before BEGIN"),
            U.To_Unbounded_String ("kept in command-line order"),
            U.To_Unbounded_String ("read AWK source from a file"),
            U.To_Unbounded_String ("multiple files are concatenated"),
            U.To_Unbounded_String ("style CLI-owned help and diagnostics only"),
            U.To_Unbounded_String ("show this help and exit"),
            U.To_Unbounded_String ("show version information and exit"),
            U.To_Unbounded_String ("end option processing"),
            U.To_Unbounded_String ("filenames beginning with"),
            U.To_Unbounded_String ("POSIX awk workflow"),
            U.To_Unbounded_String ("awklib defines behavior"),
            U.To_Unbounded_String ("[options]"),
            U.To_Unbounded_String ("program-file"),
            U.To_Unbounded_String ("host I/O"),
            U.To_Unbounded_String ("AWK CLI"),
            U.To_Unbounded_String ("AWK-CLI"),
            U.To_Unbounded_String ("EOF"),
            U.To_Unbounded_String ("CLI"),
            U.To_Unbounded_String ("input standard"),
            U.To_Unbounded_String ("error AWK"),
            U.To_Unbounded_String ("AWK error"),
            U.To_Unbounded_String ("[operand...]"),
            U.To_Unbounded_String ("-f file, -ffile"),
            U.To_Unbounded_String ("-F sep, -Fsep"),
            U.To_Unbounded_String ("-v name=value, -vname=value"),
            U.To_Unbounded_String ("name=value")];
      begin
         for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
            declare
               Locale : constant String := Awk_Catalog_Policy.Supported_Locale (Locale_Index);
            begin
               if Locale /= "en" then
                  for Key_Index in 1 .. Awk_Catalog_Policy.Required_Key_Count loop
                     declare
                        Suffix : constant String := Awk_Catalog_Policy.Required_Key (Key_Index);
                     begin
                        if Text.Contains (Suffix, "awk.help.") then
                           declare
                              Value : constant String :=
                                Text.Line_Value (Catalog, Locale & "." & Suffix);
                           begin
                              for Pattern of Banned loop
                                 Require
                                   (not Text.Contains (Value, U.To_String (Pattern)),
                                    "non-English help catalog contains English fallback text: "
                                    & Locale & "." & Suffix);
                              end loop;
                           end;
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end Require_No_English_Help_Fallbacks;

      procedure Require_No_English_Diagnostic_Fallbacks is
         Banned : constant array (Positive range <>) of U.Unbounded_String :=
           [U.To_Unbounded_String ("AWK parse failed"),
            U.To_Unbounded_String ("AWK execution failed"),
            U.To_Unbounded_String ("unsupported awklib operation"),
            U.To_Unbounded_String ("localization failed for message key"),
            U.To_Unbounded_String ("unknown option"),
            U.To_Unbounded_String ("missing argument"),
            U.To_Unbounded_String ("invalid assignment"),
            U.To_Unbounded_String ("invalid color mode"),
            U.To_Unbounded_String ("cannot open"),
            U.To_Unbounded_String ("cannot read"),
            U.To_Unbounded_String ("cannot write"),
            U.To_Unbounded_String ("use --help for command-line syntax"),
            U.To_Unbounded_String ("use -- before filenames that begin with"),
            U.To_Unbounded_String ("program file"),
            U.To_Unbounded_String ("input file"),
            U.To_Unbounded_String ("output file"),
            U.To_Unbounded_String ("standard input"),
            U.To_Unbounded_String ("standard output"),
            U.To_Unbounded_String ("is unsupported because"),
            U.To_Unbounded_String ("is reserved for AWK data"),
            U.To_Unbounded_String ("error: {"),
            U.To_Unbounded_String (" / {option}"),
            U.To_Unbounded_String ("hint: {detail}"),
            U.To_Unbounded_String ("AWK-data"),
            U.To_Unbounded_String ("input standard"),
            U.To_Unbounded_String ("AWK data"),
            U.To_Unbounded_String ("unexpected internal software failure")];
      begin
         for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
            declare
               Locale : constant String := Awk_Catalog_Policy.Supported_Locale (Locale_Index);
            begin
               if Locale /= "en" then
                  for Key_Index in 1 .. Awk_Catalog_Policy.Required_Key_Count loop
                     declare
                        Suffix : constant String := Awk_Catalog_Policy.Required_Key (Key_Index);
                     begin
                        if not Text.Contains (Suffix, "awk.help.") then
                           declare
                              Value : constant String :=
                                Text.Line_Value (Catalog, Locale & "." & Suffix);
                           begin
                              for Pattern of Banned loop
                                 Require
                                   (not Text.Contains (Value, U.To_String (Pattern)),
                                    "non-English diagnostic catalog contains English fallback text: "
                                    & Locale & "." & Suffix);
                              end loop;
                           end;
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end Require_No_English_Diagnostic_Fallbacks;

      procedure Require_Reference_Cue (Suffix, Cue : String) is
      begin
         Files.Require_Contains
           ("../docs/localization-reference.md", Suffix,
            "localization reference missing cue " & Cue & " for " & Suffix,
            Quiet => True);
         Files.Require_Contains
           ("../docs/localization-reference.md", Cue,
            "localization reference missing cue " & Cue & " for " & Suffix,
            Quiet => True);

         for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
            declare
               Locale : constant String := Awk_Catalog_Policy.Supported_Locale (Locale_Index);
               Value  : constant String := Text.Line_Value (Catalog, Locale & "." & Suffix);
            begin
               Require
                 (Text.Contains (Value, Cue),
                  "catalog entry missing reference cue " & Cue & ": "
                  & Locale & "." & Suffix);
            end;
         end loop;
      end Require_Reference_Cue;

      procedure Require_Reference_Cues is
      begin
         Require_Reference_Cue ("awk.help.summary", "awk");
         Require_Reference_Cue ("awk.help.summary", "awklib");
         Require_Reference_Cue ("awk.help.summary", "POSIX");
         Require_Reference_Cue ("awk.help.usage.direct_program", "awk");
         Require_Reference_Cue ("awk.help.usage.program_files", "awk");
         Require_Reference_Cue ("awk.help.usage.program_files", "-f");
         Require_Reference_Cue ("awk.help.options.field_separator", "-F");
         Require_Reference_Cue ("awk.help.options.field_separator", "FS");
         Require_Reference_Cue ("awk.help.options.variable", "-v");
         Require_Reference_Cue ("awk.help.options.variable", "BEGIN");
         Require_Reference_Cue ("awk.help.options.program_file", "-f");
         Require_Reference_Cue ("awk.help.options.program_file", "AWK");
         Require_Reference_Cue ("awk.help.options.color", "--color=auto|always|never");
         Require_Reference_Cue ("awk.help.options.help", "--help");
         Require_Reference_Cue ("awk.help.options.version", "--version");
         Require_Reference_Cue ("awk.help.options.terminator", "--");
         Require_Reference_Cue ("awk.help.operands", "-");
         Require_Reference_Cue ("awk.help.operands", "[A-Za-z_][A-Za-z0-9_]*");
         Require_Reference_Cue ("awk.help.stdin", "-");
         Require_Reference_Cue ("awk.help.exit_statuses", "0");
         Require_Reference_Cue ("awk.help.exit_statuses", "1");
         Require_Reference_Cue ("awk.help.exit_statuses", "2");
         Require_Reference_Cue ("awk.help.exit_statuses", "3");
         Require_Reference_Cue ("awk.help.exit_statuses", "70");
         Require_Reference_Cue ("awk.help.compatibility.awklib_limitations", "POSIX");
         Require_Reference_Cue ("awk.help.compatibility.awklib_limitations", "AWK");
         Require_Reference_Cue ("awk.help.compatibility.awklib_limitations", "awklib");
         Require_Reference_Cue ("awk.help.compatibility.awklib_limitations", "getline");
      end Require_Reference_Cues;
   begin
      Require (Catalog /= "", "message catalog is missing or empty");
      Require (English /= "", "English catalog shard is missing or empty");
      Require (Danish /= "", "Danish catalog shard is missing or empty");

      Require
        (Awk_Catalog_Policy.Failure_Message (Catalog) = "",
         Awk_Catalog_Policy.Failure_Message (Catalog));
      Require
        (Awk_Catalog_Policy.Failure_Message
           (English, Combined_Catalog => False, Locale => "en") = "",
         Awk_Catalog_Policy.Failure_Message
           (English, Combined_Catalog => False, Locale => "en"));
      Require
        (Awk_Catalog_Policy.Failure_Message
           (Danish, Combined_Catalog => False, Locale => "da") = "",
         Awk_Catalog_Policy.Failure_Message
           (Danish, Combined_Catalog => False, Locale => "da"));

      for Index in 1 .. Awk_Catalog_Policy.Required_Key_Count loop
         declare
            Suffix : constant String := Awk_Catalog_Policy.Required_Key (Index);
         begin
            for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
               declare
                  Locale : constant String := Awk_Catalog_Policy.Supported_Locale (Locale_Index);
               begin
                  Require_Key (Locale & "." & Suffix);
                  Require
                    (Awk_Catalog_Policy.Placeholders (Text.Line_Value (Catalog, "en." & Suffix)) =
                     Awk_Catalog_Policy.Placeholders (Text.Line_Value (Catalog, Locale & "." & Suffix)),
                     "placeholder mismatch between en and " & Locale & " for " & Suffix);
               end;
            end loop;
            Require_Shard_Key (English, "en." & Suffix, "English");
            Require_Shard_Key (Danish, "da." & Suffix, "Danish");
         end;
      end loop;
      Require_Consistent_Translations;
      Require_No_English_Help_Fallbacks;
      Require_No_English_Diagnostic_Fallbacks;
      Require_Reference_Cues;
      Put_Info ("catalog checks passed");
   end Catalogs;

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

   procedure Public_Spec_Docs is
      Specs : constant Files.Path_List := Files.List_Tree ("../src/library", "*.ads");
   begin
      for Path of Specs loop
         Ada_Source.Require_Public_GNATdoc_Tags
           (Spec_Path => U.To_String (Path));
      end loop;
      Put_Info ("public spec documentation checks passed");
   end Public_Spec_Docs;

   procedure Package_Manifest_Policy is
      function Package_Includes (Path : String) return Boolean is
      begin
         for Item of Package_Files loop
            if U.To_String (Item) = Path then
               return True;
            end if;
         end loop;

         return False;
      end Package_Includes;

      procedure Require_Packaged (Path : String) is
      begin
         Require
           (Package_Includes (Path),
            "package file list missing: " & Path);
      end Require_Packaged;
   begin
      for Path of Package_Files loop
         if U.To_String (Path) /= "bin/awk" then
            Files.Require_File ("../" & U.To_String (Path),
                                "packaged source file missing: " & U.To_String (Path));
         end if;
      end loop;
      Require_Packaged ("resources/messages/catalog.txt");
      Require_Packaged ("resources/messages/en/catalog.txt");
      Require_Packaged ("resources/messages/da/catalog.txt");
      Require_Packaged ("docs/compatibility.md");
      Require_Packaged ("docs/final-acceptance.md");
      Require_Packaged ("LICENSE");
      Files.Require_Contains
        ("../docs/releasing.md", "message catalogs",
         "release/testing docs must describe packaged resources", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "MANIFEST.txt",
         "release/testing docs must describe packaged resources", Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md", "package manifest",
         "release/testing docs must describe packaged resources", Quiet => True);
      Put_Info ("package manifest policy checks passed");
   end Package_Manifest_Policy;

   procedure Source_Policy is
      function Required_Message_Key (Key : String) return Boolean is
      begin
         for Index in 1 .. Awk_Catalog_Policy.Required_Key_Count loop
            if Key = Awk_Catalog_Policy.Required_Key (Index) then
               return True;
            end if;
         end loop;
         return False;
      end Required_Message_Key;

      function First_Unknown_Message_Key_Literal return String is
         Prefix : constant String := """awk.";

         function First_In_File (Name : String) return String is
            Source_Text : constant String := Fixtures.Read_Text_File (Name);
            Start       : Natural := Project_Tools.Text.Index (Source_Text, Prefix);
         begin
            while Start /= 0 loop
               declare
                  Key_First : constant Positive := Start + 1;
                  Key_Last  : Natural := 0;
               begin
                  for Scan in Key_First .. Source_Text'Last loop
                     if Source_Text (Scan) = '"' then
                        Key_Last := Scan - 1;
                        exit;
                     end if;
                  end loop;

                  if Key_Last >= Key_First then
                     declare
                        Key : constant String := Source_Text (Key_First .. Key_Last);
                     begin
                        if not Required_Message_Key (Key) then
                           return Name & ": " & Key;
                        end if;
                     end;
                  end if;

                  exit when Start = Source_Text'Last;
                  Start := Project_Tools.Text.Index_From (Source_Text, Prefix, Start + 1);
               end;
            end loop;

            return "";
         end First_In_File;

         function First_In_Tree (Name_Pattern : String) return String is
            Sources : constant Files.Path_List :=
              Files.List_Tree ("../src", Name_Pattern);
         begin
            for Path of Sources loop
               declare
                  Found : constant String := First_In_File (U.To_String (Path));
               begin
                  if Found /= "" then
                     return Found;
                  end if;
               end;
            end loop;

            return "";
         end First_In_Tree;

         Found : constant String := First_In_Tree ("*.ads");
      begin
         if Found /= "" then
            return Found;
         end if;

         return First_In_Tree ("*.adb");
      end First_Unknown_Message_Key_Literal;

      Unexpected : U.Unbounded_String;
      Workflow_Script : constant String :=
        Files.First_File_Name_Containing
          ("..",
           Name_Tokens =>
             [U.To_Unbounded_String (".sh"),
              U.To_Unbounded_String (".py"),
              U.To_Unbounded_String (".ps1"),
              U.To_Unbounded_String ("Makefile"),
              U.To_Unbounded_String (".js")],
           Skip_Entries =>
             [U.To_Unbounded_String (".git"),
              U.To_Unbounded_String ("alire"),
              U.To_Unbounded_String ("obj"),
              U.To_Unbounded_String ("bin"),
              U.To_Unbounded_String ("dist"),
              U.To_Unbounded_String ("config")]);
   begin
      Files.Require_Contains
        ("../src/library/awk_cli-execution.adb", "with Awklib",
         "execution adapter must bridge to awklib", Quiet => True);
      Ada_Source.Require_Only_Allowed_With_Clauses
        ("../src/library/awk_cli-execution.adb",
         "Awklib",
         [U.To_Unbounded_String ("Awklib"),
          U.To_Unbounded_String ("Awklib.Interpreter")],
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "with Awklib",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/library/awk_cli-execution.adb")]) = "",
         "only execution adapter may depend on awklib");
      Files.Require_Contains
        ("../src/library/awk_cli-localization.adb", "with Messages",
         "localization adapter must bridge to messages", Quiet => True);
      Ada_Source.Require_Only_Allowed_With_Clauses
        ("../src/library/awk_cli-localization.ads",
         "Messages",
         [U.To_Unbounded_String ("Messages.Runtime")],
         Quiet => True);
      Ada_Source.Require_Only_Allowed_With_Clauses
        ("../src/library/awk_cli-localization.adb",
         "Messages",
         [U.To_Unbounded_String ("Messages.Arguments"),
          U.To_Unbounded_String ("Messages.Result")],
         Quiet => True);
      Unexpected :=
        U.To_Unbounded_String
          (Ada_Source.First_Source_File_Containing
             ("../src",
              "with Messages",
              Allowed_Files =>
                [U.To_Unbounded_String ("../src/library/awk_cli-localization.adb"),
                 U.To_Unbounded_String ("../src/library/awk_cli-localization.ads")]));
      Require (U.To_String (Unexpected) = "",
               "only localization adapter may depend on messages: " & U.To_String (Unexpected));
      Files.Require_Contains
        ("../src/library/awk_cli-output.adb", "with Terminal_Styles",
         "presentation layer must bridge to terminal_styles", Quiet => True);
      Ada_Source.Require_Only_Allowed_With_Clauses
        ("../src/library/awk_cli-output.adb",
         "Terminal_Styles",
         [U.To_Unbounded_String ("Terminal_Styles")],
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "with Terminal_Styles",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/library/awk_cli-output.adb")]) = "",
         "only presentation layer may depend on terminal_styles");
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb", "with Hostkit",
         "platform adapter must bridge to hostkit", Quiet => True);
      Ada_Source.Require_Only_Allowed_With_Clauses
        ("../src/library/awk_cli-platform.adb",
         "Hostkit",
         [U.To_Unbounded_String ("Hostkit"),
          U.To_Unbounded_String ("Hostkit.Fs"),
          U.To_Unbounded_String ("Hostkit.Host"),
          U.To_Unbounded_String ("Hostkit.Process"),
          U.To_Unbounded_String ("Hostkit.Shell")],
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "with Hostkit",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/library/awk_cli-platform.adb")]) = "",
         "only platform adapter may depend on hostkit");
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "Ada.Text_IO.Put",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/main/awk.adb"),
               U.To_Unbounded_String ("../src/library/awk_cli-platform.adb")]) = "",
         "direct Text_IO writes must stay in main containment or platform adapter");
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "Ada.Command_Line",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/main/awk.adb"),
               U.To_Unbounded_String ("../src/library/awk_cli-platform.adb")]) = "",
         "process command-line access must stay in main containment or platform adapter");
      Ada_Source.Require_No_Code_Tokens_In_Tree
        ("../src",
         [U.To_Unbounded_String ("GNAT.OS_Lib")],
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            """/bin/sh""",
            Allowed_Files => []) = "",
         "shell executable selection must stay in hostkit");
      Ada_Source.Require_No_Code_Tokens_In_Tree
        ("../src",
         [U.To_Unbounded_String ("GNAT.Expect")],
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-output.adb",
         [U.To_Unbounded_String ("Character'Val (27)")],
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "Character'Val (27)",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/library/awk_cli-diagnostics.adb")]) = "",
         "only diagnostic escaping may inspect the ESC character");
      Ada_Source.Require_No_Code_Tokens_In_Tree
        ("../src",
         [U.To_Unbounded_String ("Character'Val(27)"),
          U.To_Unbounded_String ("ASCII.ESC"),
          U.To_Unbounded_String ("Ada.Characters.Latin_1.ESC")],
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-output.adb",
         [U.To_Unbounded_String ("""awk: """)],
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-programs.adb",
         [U.To_Unbounded_String ("""command line""")],
         Quiet => True);
      declare
         Unknown_Key : constant String := First_Unknown_Message_Key_Literal;
      begin
         Require
           (Unknown_Key = "",
            "production message key literal must be catalog-required: " & Unknown_Key);
      end;
      Ada_Source.Require_No_Code_Tokens_In_Tree
        ("../src",
         ([U.To_Unbounded_String ("gawk"),
           U.To_Unbounded_String ("mawk"),
           U.To_Unbounded_String ("nawk")]),
         Quiet => True);
      Project_Tools.AUnit_Checks.Require_Registered_Test_Packages
        (Test_Dir             => "src",
         Spec_Pattern         => "awk_tests-*.ads",
         Suite_Path           => "src/awk_tests-suite.adb",
         Documentation_Path     => "../docs/testing.md",
         Documented_Stem_Prefix => "`",
         Suite_Add_Prefix     => "Result.Add_Test (new ",
         Suite_Add_Suffix     => ".Case_Type)",
         Section_Marker       => "type Case_Type is new AUnit.Test_Cases.Test_Case",
         Quiet                => True);
      Project_Tools.Release_Checks.Require_GPR_Main_Inventory
        (Project_File       => "../awk.gpr",
         Documentation_File => "../README.md",
         Source_Directory   => "../src/main",
         Quiet              => True);
      Project_Tools.Release_Checks.Require_GPR_Main_Inventory
        (Project_File       => "awk_tests.gpr",
         Documentation_File => "../docs/testing.md",
         Source_Directory   => "src",
         Quiet              => True);
      Public_Spec_Docs;
      Files.Require_Contains
        ("src/awk_tests-process.adb", "with Project_Tools.Test_Fixtures",
         "fixture file reads must use project_tools directly", Quiet => True);
      Files.Require_Contains
        ("src/awk_tests-localization.adb", "with Project_Tools.Test_Fixtures",
         "fixture file reads must use project_tools directly", Quiet => True);
      Files.Require_Contains
        ("src/awk_tests-compatibility.adb", "with Project_Tools.Test_Fixtures",
         "fixture file reads must use project_tools directly", Quiet => True);
      Files.Require_Contains
        ("src/awk_workflows.adb", "--release",
         "release workflow must use Alire release builds", Quiet => True);
      Files.Require_Contains
        ("src/awk_workflows.adb", "Require_Clean_Repository;",
         "release workflow must check git status", Quiet => True);
      Files.Require_File
        ("../.github/workflows/ci.yml",
         "CI workflow must be present", Quiet => True);
      Files.Require_Contains
        ("../.github/workflows/ci.yml", "./bin/awk_workflows release",
         "CI workflow must delegate release gates to Ada tooling",
         Quiet => True);
      Require
        (not Files.File_Contains ("src/awk_workflows.adb", "release"") then" & ASCII.LF &
                                             "      Verify;"),
         "release workflow must not reuse development verify gate");
      Require
        (Workflow_Script = "",
         "workflow logic must not use shell or scripting files: " & Workflow_Script);
      Put_Info ("source policy checks passed");
   end Source_Policy;

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
      Catalogs;
      Conformance;
      Exit_Status_Drift;
      Option_Drift;
      Package_Manifest_Policy;
      Source_Policy;
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

   procedure Package_Artifact (Release_Mode : Boolean := False) is
      Dist : constant String := "../dist/awk-0.1.0";

      procedure Create_Package_Directories is
      begin
         Dir.Create_Path (Dist);
         for Path of Package_Files loop
            Dir.Create_Path
              (Ada.Directories.Containing_Directory
                 (Files.Join (Dist, U.To_String (Path))));
         end loop;
      end Create_Package_Directories;

      procedure Add_Manifest_Line
        (Buffer : in out U.Unbounded_String;
         Path   : String)
      is
      begin
         U.Append
           (Buffer,
            Project_Tools.Release_Checks.Manifest_Line (Dist, Path) & ASCII.LF);
      end Add_Manifest_Line;

      procedure Require_Package_File (Path : String) is
         Full_Path : constant String := Files.Join (Dist, Path);
      begin
         Files.Require_File (Full_Path, "missing package file: " & Path);
         Require
           (Project_Tools.Release_Checks.File_Length (Full_Path) > 0,
            "empty package file: " & Path);
      end Require_Package_File;

      procedure Copy_Package_File (Path : String) is
         Source : constant String :=
           (if Path = "bin/awk" then Files.Join ("..", "bin/awk")
            else Files.Join ("..", Path));
      begin
         Files.Copy_File
           (Source          => Source,
            Target          => Files.Join (Dist, Path),
            Failure_Message => "copy failed",
            Quiet           => True);
      end Copy_Package_File;

      Manifest : U.Unbounded_String;
      Manifest_Path : constant String := Files.Join (Dist, "MANIFEST.txt");
   begin
      if Release_Mode then
         Project_Tools.Alire.Run_Build (Directory => Root, Release_Mode => True);
         Project_Tools.Alire.Run_Build (Directory => ".", Release_Mode => True);
      else
         Build;
      end if;
      Files.Delete_Tree ("../dist");
      Create_Package_Directories;
      for Path of Package_Files loop
         Copy_Package_File (U.To_String (Path));
         Require_Package_File (U.To_String (Path));
         Add_Manifest_Line (Manifest, U.To_String (Path));
      end loop;
      Files.Write_Text_File (Manifest_Path, U.To_String (Manifest));
      Require_Package_File ("MANIFEST.txt");
      Files.Require_Contains
        (Manifest_Path, "fnv1a64=",
         "package manifest must include FNV-1a-64 checksum fields",
         Quiet => True);
      Require
        (not Files.File_Contains (Manifest_Path, " checksum="),
         "package manifest must not use legacy checksum field");
      Require
        (Project_Tools.Release_Checks.Manifest_Line_Count (Manifest_Path) = Package_Files'Length,
         "package manifest must contain one line per packaged file");
      for Path of Package_Files loop
         Project_Tools.Release_Checks.Require_Manifest_Entry
           (Manifest_Path, Dist, U.To_String (Path), Quiet => True);
      end loop;
      Put_Info ("packaged " & Dist);
   end Package_Artifact;

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
      Package_Artifact;
      Build_Output_Policy;
   elsif Command = "release" then
      Require_Clean_Repository;
      Project_Tools.Alire.Run_Build (Directory => Root, Release_Mode => True);
      Project_Tools.Alire.Run_Build (Directory => ".", Release_Mode => True);
      Project_Tools.Release_Checks.Run
        ("./bin/awk_tests_main", ".", "./bin/awk_tests_main", No_Arguments);
      Metadata;
      Docs;
      Catalogs;
      Conformance;
      Source_Policy;
      Exit_Status_Drift;
      Option_Drift;
      Package_Manifest_Policy;
      Install_Boundary;
      Package_Artifact (Release_Mode => True);
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
