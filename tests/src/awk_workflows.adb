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
with Project_Tools.Text;
with Project_Tools.TOML;

procedure Awk_Workflows is
   package CLI renames Ada.Command_Line;
   package Dir renames Ada.Directories;
   package Ada_Source renames Project_Tools.Ada_Source;
   package Manifests renames Project_Tools.Alire_Manifests.Validation;
   package Proc renames Project_Tools.Processes;
   package Files renames Project_Tools.Files;
   package Text renames Project_Tools.Text;
   package TOML renames Project_Tools.TOML;
   package U renames Ada.Strings.Unbounded;

   Root : constant String := "..";
   Alr  : constant String := Proc.Locate_Command ("alr");

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

   procedure Run_Alr_Build (Directory : String; Release_Mode : Boolean := False) is
   begin
      Project_Tools.Alire.Run_Build
        (Directory    => Directory,
         Release_Mode => Release_Mode);
   end Run_Alr_Build;

   procedure Run_Binary (Directory, Program : String) is
      Args : GNAT.OS_Lib.Argument_List (1 .. 0);
   begin
      Project_Tools.Release_Checks.Run (Program, Directory, Program, Args);
   end Run_Binary;

   procedure Build is
   begin
      Run_Alr_Build (Root);
      Run_Alr_Build (".");
   end Build;

   procedure Test is
   begin
      Run_Alr_Build (".");
      Run_Binary (".", "./bin/awk_tests_main");
   end Test;

   procedure Require_Clean_Repository is
   begin
      Project_Tools.Release_Checks.Require_Clean_Git_Worktree
        ("awk", Root, Quiet => True);
   end Require_Clean_Repository;

   function File_Text (Path : String) return String is
     (U.To_String (Text.Read_Text_File (Path)));

   function Contains (Text, Pattern : String) return Boolean is
     (Project_Tools.Text.Contains (Text, Pattern));

   function File_Has (Path, Pattern : String) return Boolean is
     (Files.File_Contains (Path, Pattern));

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
   begin
      Files.Require_Files (Required_Docs, "missing required documentation");
      Require
        (File_Has ("../README.md", "does not claim complete POSIX conformance"),
         "README must not claim full POSIX conformance");
      Require
        (File_Has ("../README.md", "./bin/awk_tests_main"),
         "README must document the current AUnit executable");
      Require
        (File_Has ("../README.md", "--color=auto|always|never"),
         "README must document color policy");
      Require
        (File_Has ("../README.md", "Windows"),
         "README must include Windows quoting guidance");
      Require
        (File_Has ("../LICENSE", "MIT License"),
         "LICENSE must contain MIT license text");
      Require
        (File_Has ("../docs/command-line-reference.md", "-f program-file"),
         "command-line reference must document program-file invocation");
      Require
        (File_Has ("../docs/command-line-reference.md", "Runtime assignment operands"),
         "command-line reference must document runtime assignment operands");
      Require
        (File_Has ("../docs/command-line-reference.md",
                   "Supports_Positional_Runtime_Assignments = True"),
         "command-line reference must document positional assignment capability");
      Require
        (File_Has ("../docs/architecture.md", "Awk_CLI.Execution"),
         "architecture docs must document execution adapter isolation");
      Require
        (File_Has ("../docs/architecture.md", "Invocation_Context"),
         "architecture docs must document testable invocation context");
      Require
        (File_Has ("../docs/compatibility.md",
                   "No current entries are classified as unsupported"),
         "compatibility docs must state the active limitation position");
      Require
        (File_Has ("../docs/compatibility.md", "AWK-COMPAT-GETLINE-002"),
         "compatibility docs must include reviewed compatibility IDs");
      Require
        (File_Has ("../docs/compatibility.md", "Test reference"),
         "compatibility docs must include test references");
      Require
        (File_Has ("../docs/compatibility.md", "Status"),
         "compatibility docs must include status names");
      Require
        (File_Has ("../docs/compatibility.md", "Source"),
         "compatibility docs must include limitation source");
      Require
        (File_Has ("../docs/diagnostics.md", "destination-aware terminal detection"),
         "diagnostics docs must document destination-aware terminal styling");
      Require
        (File_Has ("../docs/diagnostics.md", "open failures from read failures"),
         "diagnostics docs must document open/read failure distinction");
      Require
        (File_Has ("../docs/localization.md", "awk.internal.localization_failed")
         and then File_Has ("../docs/localization.md", "last-resort containment"),
         "localization docs must document catalog-backed render fallback");
      Require
        (File_Has ("../docs/localization.md", "Localization Reference")
         and then File_Has ("../docs/localization-reference.md", "POSIX `awk` utility text")
         and then File_Has ("../docs/localization-reference.md", "GNU awk")
         and then File_Has ("../docs/localization-reference.md", "BWK awk")
         and then File_Has ("../docs/localization-reference.md", "BusyBox awk")
         and then File_Has ("../docs/localization-reference.md", "Reference run record")
         and then File_Has ("../docs/localization-reference.md", "/usr/bin/mawk -W help")
         and then File_Has ("../docs/localization-reference.md", "/usr/bin/busybox awk --help")
         and then File_Has ("../docs/localization-reference.md", "Reference comparison checklist")
         and then File_Has ("../docs/localization-reference.md", "Machine-checked reference cues"),
         "localization docs must require comparison with other AWK reference text");
      Require
        (File_Has ("../docs/localization.md", "supported European state-language locale set")
         and then File_Has ("../docs/testing.md", "every supported European" & ASCII.LF &
                                               "state-language locale"),
         "localization docs must document supported European locale catalog validation");
      Require
        (File_Has ("../docs/architecture.md", "main input is callback-driven"),
         "architecture docs must document memory-oriented host integration");
      Require
        (File_Has ("../docs/architecture.md", "AWK record splitting"),
         "architecture docs must document awklib text streaming callbacks");
      Require
        (File_Has ("../docs/architecture.md",
                   "Supports_Redirection_Append_Mode = True"),
         "architecture docs must document append redirection capability");
      Require
        (File_Has ("../docs/architecture.md",
                   "Supports_Streaming_Execution = True"),
         "architecture docs must document streaming capability");
      Require
        (File_Has ("../docs/testing.md", "structured diagnostic"),
         "testing docs must mention structured diagnostic assertions");
      Require
        (File_Has ("../docs/testing.md", "awk_tests-cli_options"),
         "testing docs must document subsystem test packages");
      Require
        (File_Has ("../docs/testing.md", "conformance manifest"),
         "testing docs must mention conformance manifest validation");
      Require
        (File_Has ("../docs/testing.md", "Alire install-boundary"),
         "testing docs must mention install-boundary validation");
      Require
        (File_Has ("../docs/testing.md", "checks local Alire workspace pins"),
         "testing docs must mention workspace pin validation");
      Require
        (File_Has ("../docs/testing.md", "parsed Ada `with` clauses"),
         "testing docs must mention parsed Ada source-policy validation");
      Require
        (File_Has ("../docs/testing.md", "FNV-1a-64"),
         "testing docs must mention release checksum validation");
      Require
        (File_Has ("../docs/building.md", "install boundary"),
         "building docs must mention install boundary verification");
      Require
        (File_Has ("../docs/building.md", "generated release packages"),
         "building docs must mention generated release package cleanup");
      Require
        (File_Has ("../docs/building.md", "local Alire workspace pins"),
         "building docs must mention workspace pin verification");
      Require
        (File_Has ("../docs/releasing.md", "--release --profiles=*=release"),
         "release docs must document release-profile builds");
      Require
        (File_Has ("../docs/releasing.md", "clean git working tree"),
         "release docs must document clean-tree enforcement");
      Require
        (File_Has ("../docs/releasing.md", "local Alire workspace pins"),
         "release docs must mention workspace pin verification");
      Require
        (File_Has ("../docs/releasing.md", "FNV-1a-64"),
         "release docs must document manifest checksum algorithm");
      Require
        (File_Has ("../docs/releasing.md", "dependency policy")
         and then File_Has ("../docs/releasing.md", "traceability matrix"),
         "release docs must document packaged audit documentation");
      Require
        (File_Has ("../docs/final-acceptance.md", "<!-- generated:awk-acceptance -->")
         and then File_Has ("../docs/final-acceptance.md", "Normative acceptance gates")
         and then File_Has ("../docs/ai/traceability.md", "| 49 | Definition of done |"),
         "final acceptance and traceability docs must describe release gates");
      Require
        (File_Has ("../docs/releasing.md", "`terminal_styles = ""=0.1.0-dev""` and `hostkit = ""=0.1.0-dev""`")
         and then File_Has ("../docs/ai/traceability.md", "`terminal_styles = ""=0.1.0-dev""` and" & ASCII.LF &
                                                        "`hostkit = ""=0.1.0-dev""`"),
         "release traceability docs must mention current dev dependency constraints");
      Require
        (File_Has ("../docs/releasing.md", "temporary prefix"),
         "release docs must document temporary install-prefix validation");
      Require
        (File_Has ("../docs/dependency-policy.md", "workspace release model"),
         "dependency policy must document workspace release model");
      Require
        (File_Has ("../docs/dependency-policy.md", "No direct dependency may use an unrestricted wildcard"),
         "dependency policy must reject wildcard release constraints");
      Require
        (File_Has ("../docs/dependency-policy.md", "Publish readiness is a separate gate"),
         "dependency policy must document publish readiness separation");
      Require
        (File_Has ("../docs/ai/workflows.md", "parsed" & ASCII.LF &
                                             "Ada `with` clauses"),
         "AI workflow docs must mention parsed Ada source-policy validation");
      Require
        (File_Has ("../docs/ai/workflows.md", "expected local" & ASCII.LF &
                                             "Alire workspace pins"),
         "AI workflow docs must mention workspace pin validation");
      Require
        (File_Has ("../docs/testing.md", "production source while allowing the diagnostic" & ASCII.LF &
                                      "sanitizer to recognize ESC")
         and then File_Has ("../docs/ai/workflows.md",
                            "no handwritten ANSI code tokens in production source")
         and then File_Has ("../docs/ai/workflows.md",
                            "diagnostic ESC recognition for escaping"),
         "workflow docs must describe production-wide ANSI source policy");
      Require
        (File_Has ("../docs/testing.md", "command-line access stays in the main" & ASCII.LF &
                                      "containment boundary or platform adapter")
         and then File_Has ("../docs/ai/workflows.md",
                            "command-line access confined to main containment" & ASCII.LF &
                            "or the platform adapter")
         and then File_Has ("../docs/testing.md",
                            "rejects direct `GNAT.OS_Lib`," & ASCII.LF &
                            "`GNAT.Expect`, and `/bin/sh` production use in favor of `hostkit`")
         and then File_Has ("../docs/ai/workflows.md",
                            "direct `GNAT.OS_Lib`, `GNAT.Expect`, and `/bin/sh`" & ASCII.LF &
                            "production use rejected in favor of `hostkit`"),
         "workflow docs must describe process-boundary source policy");
      Require
        (File_Has ("../docs/architecture.md", "only production package that directly depends on" & ASCII.LF &
                                           "  `hostkit`")
         and then File_Has ("../docs/ai/package-contracts.md",
                            "Only `Awk_CLI.Platform` may call `hostkit`."),
         "architecture docs must describe hostkit platform boundary");
      Require
        (File_Has ("../docs/ai/traceability.md", "| 1 | Project identity |"),
         "traceability docs must map project identity");
      Require
        (File_Has ("../docs/ai/traceability.md", "| 13 | Execution adapter |"),
         "traceability docs must map execution adapter");
      Require
        (File_Has ("../docs/ai/traceability.md", "| 39 | Tooling requirements |"),
         "traceability docs must map tooling requirements");
      Require
        (File_Has ("../docs/ai/traceability.md", "| 49 | Definition of done |"),
         "traceability docs must map definition of done");
      Put_Info ("documentation checks passed");
   end Docs;

   procedure Metadata is
      Root_Alire  : constant String := File_Text ("../alire.toml");
      Tests_Alire : constant String := File_Text ("alire.toml");
   begin
      Require (TOML.String_Value_After (Root_Alire, "name =", Root_Alire'First) = "awk",
               "root crate name must be awk");
      Require (File_Has ("../alire.toml", "executables = [""awk""]"),
               "root crate must install executable awk");
      Require (File_Has ("../alire.toml", "project-files = [""awk.gpr""]"),
               "root crate must use awk.gpr");
      Require (File_Has ("../alire.toml", "awklib = "),
               "root crate must depend on awklib");
      Require (File_Has ("../alire.toml", "terminal_styles = "),
               "root crate must depend on terminal_styles");
      Require (File_Has ("../alire.toml", "messages = "),
               "root crate must depend on messages");
      Require (File_Has ("../alire.toml", "hostkit = "),
               "root crate must depend on hostkit");
      Require (not Contains (Root_Alire, "awklib = ""*"""),
               "root awklib dependency must not use wildcard constraint");
      Require (not Contains (Root_Alire, "terminal_styles = ""*"""),
               "root terminal_styles dependency must not use wildcard constraint");
      Require (not Contains (Root_Alire, "messages = ""*"""),
               "root messages dependency must not use wildcard constraint");
      Require (not Contains (Root_Alire, "hostkit = ""*"""),
               "root hostkit dependency must not use wildcard constraint");
      Require
        (File_Has ("../docs/dependency-policy.md", "terminal_styles = ""=0.1.0-dev"""),
         "dependency policy must document the current terminal_styles dev constraint");
      Require
        (File_Has ("../docs/dependency-policy.md", "hostkit = ""=0.1.0-dev"""),
         "dependency policy must document the current hostkit dev constraint");
      Require (TOML.String_Value_After (Tests_Alire, "name =", Tests_Alire'First) = "awk_tests",
               "tests crate name must be awk_tests");
      Require (File_Has ("alire.toml", "awk = "),
               "tests crate must depend on awk");
      Require (File_Has ("alire.toml", "aunit = "),
               "tests crate must depend on AUnit");
      Require (File_Has ("alire.toml", "project_tools = "),
               "tests crate must depend on project_tools");
      Require (File_Has ("alire.toml", "messages = "),
               "tests crate must depend on messages for catalog consistency checks");
      Require (File_Has ("alire.toml", "awk = { path = "".."" }"),
               "tests crate must pin awk relatively");
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
      Require (File_Has ("../awk.gpr", "-gnat2022"),
               "root project must compile with Ada 2022");
      Require (File_Has ("awk_tests.gpr", "-gnat2022"),
               "tests project must compile with Ada 2022");
      Require (File_Has ("../awk.gpr", "for Main use (""awk.adb"")"),
               "root project main must be awk.adb");
      Require (File_Has ("awk_tests.gpr", "awk_workflows.adb"),
               "tests project must build workflow executable");
      Require (TOML.String_Value_After (Root_Alire, "licenses =", Root_Alire'First) = "MIT",
               "root crate must declare MIT license");
      Require (TOML.String_Value_After (Tests_Alire, "licenses =", Tests_Alire'First) = "MIT",
               "tests crate must declare MIT license");
      Put_Info ("metadata checks passed");
   end Metadata;

   procedure Catalogs is
      Catalog    : constant String := File_Text ("../resources/messages/catalog.txt");
      English    : constant String := File_Text ("../resources/messages/en/catalog.txt");
      Danish     : constant String := File_Text ("../resources/messages/da/catalog.txt");

      procedure Require_Key (Key : String) is
      begin
         Require (Contains (Catalog, Key & " ="), "message catalog missing key: " & Key);
         Require (Text.Line_Value (Catalog, Key) /= "",
                  "message catalog has empty key: " & Key);
      end Require_Key;

      procedure Require_Shard_Key (Shard, Key, Name : String) is
      begin
         Require (Contains (Shard, Key & " ="),
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
            U.To_Unbounded_String ("getline behavior follows awklib.")];
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
                        if Contains (Suffix, "awk.help.") then
                           declare
                              Value : constant String :=
                                Text.Line_Value (Catalog, Locale & "." & Suffix);
                           begin
                              for Pattern of Banned loop
                                 Require
                                   (not Contains (Value, U.To_String (Pattern)),
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
            U.To_Unbounded_String ("use --help for command-line syntax"),
            U.To_Unbounded_String ("use -- before filenames that begin with"),
            U.To_Unbounded_String ("program file"),
            U.To_Unbounded_String ("input file"),
            U.To_Unbounded_String ("output file"),
            U.To_Unbounded_String ("standard input"),
            U.To_Unbounded_String ("standard output"),
            U.To_Unbounded_String ("is unsupported because"),
            U.To_Unbounded_String ("is reserved for AWK data"),
            U.To_Unbounded_String ("error: {")];
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
                        if not Contains (Suffix, "awk.help.") then
                           declare
                              Value : constant String :=
                                Text.Line_Value (Catalog, Locale & "." & Suffix);
                           begin
                              for Pattern of Banned loop
                                 Require
                                   (not Contains (Value, U.To_String (Pattern)),
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
         Require
           (File_Has ("../docs/localization-reference.md", Suffix)
            and then File_Has ("../docs/localization-reference.md", Cue),
            "localization reference missing cue " & Cue & " for " & Suffix);

         for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
            declare
               Locale : constant String := Awk_Catalog_Policy.Supported_Locale (Locale_Index);
               Value  : constant String := Text.Line_Value (Catalog, Locale & "." & Suffix);
            begin
               Require
                 (Contains (Value, Cue),
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
      Manifest : constant String := File_Text ("conformance/manifest/cases.txt");

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
         Require (File_Text ("conformance/" & Case_File) /= "",
                  "conformance case file is empty: " & Case_File);
         Require (File_Text ("conformance/" & Expected) /= "",
                  "conformance expected file is empty: " & Expected);
      end Require_Case;
   begin
      Require (Manifest /= "", "conformance manifest is missing or empty");
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
      Source  : constant String := File_Text ("../src/library/awk_cli-diagnostics.ads");
      Docs    : constant String := File_Text ("../docs/diagnostics.md");
      Allowed : U.Unbounded_String;

      procedure Require_Exit (Name : String) is
         Value : constant String := Exit_Constant_Value (Source, Name);
      begin
         Require (Value /= "", "exit status constant missing from source: " & Name);
         U.Append (Allowed, " " & Value & " ");
         Require
           (Contains (Docs, "| `" & Value & "` |"),
            "exit status " & Value & " from " & Name & " is not documented");
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
                    (Contains (U.To_String (Allowed), " " & Value & " "),
                     "exit status " & Value & " is documented but not defined");
               end;
            end if;
            From := Mark + 3;
         end;
      end loop;
      Put_Info ("exit status drift checks passed");
   end Exit_Status_Drift;

   procedure Option_Drift is
      Reference : constant String := File_Text ("../docs/command-line-reference.md");
      Catalog   : constant String := File_Text ("../resources/messages/catalog.txt");

      procedure Require_Option (Spelling : String) is
      begin
         Require
           (Contains (Reference, Spelling),
            "command-line reference missing accepted option: " & Spelling);
         Require
           (Contains (Catalog, Spelling),
            "help catalog missing accepted option: " & Spelling);
      end Require_Option;
   begin
      Require_Option ("-F");
      Require_Option ("-v");
      Require_Option ("-f");
      Require_Option ("--color");
      Require_Option ("--help");
      Require_Option ("--version");
      Require_Option ("--");
      Require
        (Contains (Reference, "--color=auto|always|never")
         and then Contains (Catalog, "--color=auto|always|never"),
         "color modes must stay documented in reference and help catalog");
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
      procedure Require_Packaged (Path : String) is
      begin
         Require
           (Contains (File_Text ("src/awk_workflows.adb"),
                      "U.To_Unbounded_String (""" & Path & """)"),
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
      Require
        (File_Has ("../docs/releasing.md", "message catalogs")
         and then File_Has ("../docs/testing.md", "package manifest"),
         "release/testing docs must describe packaged resources");
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
            Source_Text : constant String := File_Text (Name);
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

      function First_Workflow_Script return String is
      begin
         return Files.First_File_Name_Containing
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
      end First_Workflow_Script;

      Unexpected : U.Unbounded_String;
   begin
      Require
        (File_Has ("../src/library/awk_cli-execution.adb", "with Awklib"),
         "execution adapter must bridge to awklib");
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
      Require
        (File_Has ("../src/library/awk_cli-localization.adb", "with Messages"),
         "localization adapter must bridge to messages");
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
      Require
        (File_Has ("../src/library/awk_cli-output.adb", "with Terminal_Styles"),
         "presentation layer must bridge to terminal_styles");
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
      Require
        (File_Has ("../src/library/awk_cli-platform.adb", "with Hostkit"),
         "platform adapter must bridge to hostkit");
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
      Require
        (not File_Has ("../src/library/awk_cli-output.adb", """awk: """),
         "diagnostic header text must be catalog-backed");
      Require
        (not File_Has ("../src/library/awk_cli-programs.adb", """command line"""),
         "direct source display name must be catalog-backed");
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
         Suite_Add_Prefix     => "Result.Add_Test (new ",
         Suite_Add_Suffix     => ".Case_Type)",
         Section_Marker       => "type Case_Type is new AUnit.Test_Cases.Test_Case",
         Quiet                => True);
      Public_Spec_Docs;
      Files.Require_Files
        ([U.To_Unbounded_String ("src/awk_tests-support.ads"),
          U.To_Unbounded_String ("src/awk_tests-support.adb")],
         "shared test helpers must live in a support package");
      Require
        (File_Has ("src/awk_workflows.adb", "--release"),
         "release workflow must use Alire release builds");
      Require
        (File_Has ("src/awk_workflows.adb", "status"),
         "release workflow must check git status");
      Require
        (not File_Has ("src/awk_workflows.adb", "release"") then" & ASCII.LF &
                                             "      Verify;"),
         "release workflow must not reuse development verify gate");
      Require
        (First_Workflow_Script = "",
         "workflow logic must not use shell or scripting files: " & First_Workflow_Script);
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
      Require (Alr /= "", "alr executable not found");
      Files.Delete_Tree (Prefix);

      if Proc.Run_Status ("alr install", Root, Alr, Install_Args, Output, Quiet => True) /= 0 then
         Fail ("alr install failed");
      end if;

      Files.Require_File (Prefix & "/bin/awk", "installed awk executable missing");
      if Proc.Run_Status
          ("installed awk --version", Root, Prefix & "/bin/awk", Version_Args,
           Output, Quiet => True) /= 0
      then
         Fail ("installed awk executable failed");
      end if;
      Require (Contains (U.To_String (Output), "awk 0.1.0"),
               "installed awk version output is unexpected");

      Files.Delete_Tree (Prefix);
      Put_Info ("install boundary checks passed");
   end Install_Boundary;

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

   procedure Copy_File (Source, Target : String) is
   begin
      Files.Delete_File_If_Present (Target);
      Dir.Copy_File (Source, Target);
   exception
      when others =>
         Fail ("copy failed: " & Source & " -> " & Target);
   end Copy_File;

   procedure Package_Artifact (Release_Mode : Boolean := False) is
      Dist : constant String := "../dist/awk-0.1.0";
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
      begin
         Files.Require_File (Dist & "/" & Path, "missing package file: " & Path);
         Require
           (Project_Tools.Release_Checks.File_Length (Dist & "/" & Path) > 0,
            "empty package file: " & Path);
      end Require_Package_File;

      procedure Copy_Package_File (Path : String) is
         Source : constant String :=
           (if Path = "bin/awk" then "../bin/awk" else "../" & Path);
      begin
         Copy_File (Source, Dist & "/" & Path);
      end Copy_Package_File;

      Manifest : U.Unbounded_String;
      Manifest_Path : constant String := Dist & "/MANIFEST.txt";
   begin
      if Release_Mode then
         Run_Alr_Build (Root, Release_Mode => True);
         Run_Alr_Build (".", Release_Mode => True);
      else
         Build;
      end if;
      Files.Delete_Tree ("../dist");
      Dir.Create_Path (Dist & "/bin");
      Dir.Create_Path (Dist & "/resources/messages");
      Dir.Create_Path (Dist & "/resources/messages/en");
      Dir.Create_Path (Dist & "/resources/messages/da");
      Dir.Create_Path (Dist & "/docs");
      Dir.Create_Path (Dist & "/docs/ai");
      for Path of Package_Files loop
         Copy_Package_File (U.To_String (Path));
         Require_Package_File (U.To_String (Path));
         Add_Manifest_Line (Manifest, U.To_String (Path));
      end loop;
      Files.Write_Text_File (Manifest_Path, U.To_String (Manifest));
      Require_Package_File ("MANIFEST.txt");
      Require
        (File_Has (Manifest_Path, "fnv1a64="),
         "package manifest must include FNV-1a-64 checksum fields");
      Require
        (not File_Has (Manifest_Path, " checksum="),
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
   elsif Command = "test" then
      Test;
   elsif Command = "verify" then
      Verify;
   elsif Command = "docs" then
      Docs;
   elsif Command = "clean" then
      Clean;
   elsif Command = "package" then
      Package_Artifact;
   elsif Command = "release" then
      Require_Clean_Repository;
      Run_Alr_Build (Root, Release_Mode => True);
      Run_Alr_Build (".", Release_Mode => True);
      Run_Binary (".", "./bin/awk_tests_main");
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
