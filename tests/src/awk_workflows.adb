with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Exceptions;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Interfaces;

with GNAT.OS_Lib;

with Awk_Catalog_Policy;
with Project_Tools.Alire;
with Project_Tools.AUnit_Checks;
with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Text;
with Project_Tools.TOML;
with Project_Tools.Tree_Checks;

procedure Awk_Workflows is
   package CLI renames Ada.Command_Line;
   package Dir renames Ada.Directories;
   package Proc renames Project_Tools.Processes;
   package Files renames Project_Tools.Files;
   package Text renames Project_Tools.Text;
   package TOML renames Project_Tools.TOML;
   package U renames Ada.Strings.Unbounded;
   use type Interfaces.Unsigned_64;

   Root : constant String := "..";
   Alr  : constant String := Proc.Locate_Command ("alr");
   Env  : constant String := Proc.Locate_Command ("env");

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
      package Env_Vars renames Ada.Environment_Variables;

      function Derived_Home return String is
         Marker : constant String := "/.getada/bin/alr";
      begin
         if Alr'Length > Marker'Length
           and then Alr (Alr'Last - Marker'Length + 1 .. Alr'Last) = Marker
         then
            return Alr (Alr'First .. Alr'Last - Marker'Length);
         else
            return "";
         end if;
      end Derived_Home;

      function Value_Or_Empty (Name : String) return String is
      begin
         if Env_Vars.Exists (Name) then
            return Env_Vars.Value (Name);
         else
            return "";
         end if;
      end Value_Or_Empty;

      Alr_Args : constant GNAT.OS_Lib.Argument_List :=
        (if Release_Mode
         then [new String'("--non-interactive"),
               new String'("build"),
               new String'("--release"),
               new String'("--profiles=*=release")]
         else Project_Tools.Alire.Noninteractive_Build_Args);
      Home : constant String := Derived_Home;
      Path : constant String := Value_Or_Empty ("PATH");
   begin
      Require (Alr /= "", "alr executable not found");

      if Env /= "" and then Home /= "" then
         declare
            Args : GNAT.OS_Lib.Argument_List (1 .. Alr_Args'Length + 6);
         begin
            Args (1) := new String'("-i");
            Args (2) := new String'("HOME=" & Home);
            Args (3) := new String'("XDG_DATA_HOME=" & Home & "/.local/share");
            Args (4) := new String'("XDG_CONFIG_HOME=" & Home & "/.config");
            Args (5) := new String'("PATH=" & Path);
            Args (6) := new String'(Alr);

            for Index in Alr_Args'Range loop
               Args (Index - Alr_Args'First + 7) := new String'(Alr_Args (Index).all);
            end loop;

            if Proc.Run_Status ("alr build", Directory, Env, Args) /= 0 then
               Fail ("alr build failed in " & Directory);
            end if;
         end;
      elsif Proc.Run_Status ("alr build", Directory, Alr, Alr_Args) /= 0 then
         Fail ("alr build failed in " & Directory);
      end if;
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

   function Line_Value (Text, Key : String) return String is
      Prefix : constant String := Key & " =";
      Start  : Positive;
   begin
      if Text'Length < Prefix'Length then
         return "";
      end if;

      for Index in Text'First .. Text'Last - Prefix'Length + 1 loop
         if (Index = Text'First or else Text (Index - 1) = ASCII.LF)
           and then Text (Index .. Index + Prefix'Length - 1) = Prefix
         then
            Start := Index + Prefix'Length;
            if Start <= Text'Last and then Text (Start) = ' ' then
               Start := Start + 1;
            end if;
            for Last in Start .. Text'Last loop
               if Text (Last) = ASCII.LF then
                  return Text (Start .. Last - 1);
               end if;
            end loop;
            return Text (Start .. Text'Last);
         end if;
      end loop;
      return "";
   end Line_Value;

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
         U.To_Unbounded_String ("../docs/testing.md"),
         U.To_Unbounded_String ("../docs/building.md"),
         U.To_Unbounded_String ("../docs/releasing.md"),
         U.To_Unbounded_String ("../docs/ai/project-map.md"),
         U.To_Unbounded_String ("../docs/ai/package-contracts.md"),
         U.To_Unbounded_String ("../docs/ai/invariants.md"),
         U.To_Unbounded_String ("../docs/ai/workflows.md"),
         U.To_Unbounded_String ("../docs/ai/prohibited-designs.md")];
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
                   "No current compatibility-registry entries are active"),
         "compatibility docs must state the empty active registry");
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
        (File_Has ("../docs/testing.md", "FNV-1a-64"),
         "testing docs must mention release checksum validation");
      Require
        (File_Has ("../docs/building.md", "install boundary"),
         "building docs must mention install boundary verification");
      Require
        (File_Has ("../docs/releasing.md", "--release --profiles=*=release"),
         "release docs must document release-profile builds");
      Require
        (File_Has ("../docs/releasing.md", "clean git working tree"),
         "release docs must document clean-tree enforcement");
      Require
        (File_Has ("../docs/releasing.md", "FNV-1a-64"),
         "release docs must document manifest checksum algorithm");
      Require
        (File_Has ("../docs/releasing.md", "temporary prefix"),
         "release docs must document temporary install-prefix validation");
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
      Require (TOML.String_Value_After (Tests_Alire, "name =", Tests_Alire'First) = "awk_tests",
               "tests crate name must be awk_tests");
      Require (File_Has ("alire.toml", "awk = "),
               "tests crate must depend on awk");
      Require (File_Has ("alire.toml", "aunit = "),
               "tests crate must depend on AUnit");
      Require (File_Has ("alire.toml", "project_tools = "),
               "tests crate must depend on project_tools");
      Require (File_Has ("alire.toml", "awk = { path = "".."" }"),
               "tests crate must pin awk relatively");
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
         Require (Line_Value (Catalog, Key) /= "", "message catalog has empty key: " & Key);
      end Require_Key;

      procedure Require_Shard_Key (Shard, Key, Name : String) is
      begin
         Require (Contains (Shard, Key & " ="),
                  Name & " catalog shard missing key: " & Key);
         Require (Line_Value (Shard, Key) /= "",
                  Name & " catalog shard has empty key: " & Key);
      end Require_Shard_Key;
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
            Require_Key ("en." & Suffix);
            Require_Key ("da." & Suffix);
            Require_Shard_Key (English, "en." & Suffix, "English");
            Require_Shard_Key (Danish, "da." & Suffix, "Danish");
            Require
              (Awk_Catalog_Policy.Placeholders (Line_Value (Catalog, "en." & Suffix)) =
               Awk_Catalog_Policy.Placeholders (Line_Value (Catalog, "da." & Suffix)),
               "placeholder mismatch between locales for " & Suffix);
         end;
      end loop;
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

   procedure Source_Policy is
      function Allowed_Path (Path, Allowed : String) return Boolean is
      begin
         return Path = Allowed;
      end Allowed_Path;

      function First_Workflow_Script return String is
         All_Files : constant Files.Path_List :=
           Files.List_Tree
             ("..", "*",
              Skip_Entries =>
                [U.To_Unbounded_String (".git"),
                 U.To_Unbounded_String ("alire"),
                 U.To_Unbounded_String ("obj"),
                 U.To_Unbounded_String ("bin"),
                 U.To_Unbounded_String ("dist"),
                 U.To_Unbounded_String ("config")]);
      begin
         for Path of All_Files loop
            declare
               Name : constant String := U.To_String (Path);
           begin
               if Contains (Name, ".sh")
                 or else Contains (Name, ".py")
                 or else Contains (Name, ".ps1")
                 or else Contains (Name, "Makefile")
                 or else Contains (Name, ".js")
               then
                  return Name;
               end if;
            end;
         end loop;
         return "";
      end First_Workflow_Script;

      function First_Unexpected_Dependency
        (Pattern      : String;
         Allowed_Body : String;
         Allowed_Spec : String := "") return String
      is
         Ads_Files : constant Files.Path_List := Files.List_Tree ("../src", "*.ads");
         Adb_Files : constant Files.Path_List := Files.List_Tree ("../src", "*.adb");
      begin
         for Path of Ads_Files loop
            declare
               Name : constant String := U.To_String (Path);
            begin
               if File_Has (Name, Pattern)
                 and then not Allowed_Path (Name, Allowed_Body)
                 and then (Allowed_Spec = "" or else not Allowed_Path (Name, Allowed_Spec))
               then
                  return Name;
               end if;
            end;
         end loop;

         for Path of Adb_Files loop
            declare
               Name : constant String := U.To_String (Path);
            begin
               if File_Has (Name, Pattern)
                 and then not Allowed_Path (Name, Allowed_Body)
                 and then (Allowed_Spec = "" or else not Allowed_Path (Name, Allowed_Spec))
               then
                  return Name;
               end if;
            end;
         end loop;

         return "";
      end First_Unexpected_Dependency;

      Unexpected : U.Unbounded_String;
      Tree_Errors : Natural := 0;
   begin
      Require
        (File_Has ("../src/library/awk_cli-execution.adb", "with Awklib"),
         "execution adapter must bridge to awklib");
      Require
        (First_Unexpected_Dependency ("with Awklib", "../src/library/awk_cli-execution.adb") = "",
         "only execution adapter may depend on awklib");
      Require
        (File_Has ("../src/library/awk_cli-localization.adb", "with Messages"),
         "localization adapter must bridge to messages");
      Unexpected :=
        U.To_Unbounded_String
          (First_Unexpected_Dependency
             ("with Messages",
              "../src/library/awk_cli-localization.adb",
              "../src/library/awk_cli-localization.ads"));
      Require (U.To_String (Unexpected) = "",
               "only localization adapter may depend on messages: " & U.To_String (Unexpected));
      Require
        (File_Has ("../src/library/awk_cli-output.adb", "with Terminal_Styles"),
         "presentation layer must bridge to terminal_styles");
      Require
        (First_Unexpected_Dependency ("with Terminal_Styles", "../src/library/awk_cli-output.adb") = "",
         "only presentation layer may depend on terminal_styles");
      Require
        (not File_Has ("../src/library/awk_cli-output.adb", "Character'Val (27)"),
         "presentation layer must not emit handwritten ANSI escapes");
      Project_Tools.Tree_Checks.Check_No_Forbidden_Tokens
        (Errors           => Tree_Errors,
         Dir              => "../src",
         Forbidden_Tokens =>
           [U.To_Unbounded_String ("gawk"),
            U.To_Unbounded_String ("mawk"),
            U.To_Unbounded_String ("nawk")],
         Purpose          => "production source",
         Quiet            => True);
      Require (Tree_Errors = 0, "production source must not reference external AWK fallbacks");
      Project_Tools.AUnit_Checks.Require_Registered_Test_Packages
        (Test_Dir             => "src",
         Spec_Pattern         => "awk_tests-*.ads",
         Suite_Path           => "src/awk_tests-suite.adb",
         Suite_Add_Prefix     => "Result.Add_Test (new ",
         Suite_Add_Suffix     => ".Case_Type)",
         Section_Marker       => "type Case_Type is new AUnit.Test_Cases.Test_Case",
         Quiet                => True);
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
      Source_Policy;
      Install_Boundary;
   end Verify;

   procedure Clean is
   begin
      Files.Delete_Tree ("../obj");
      Files.Delete_Tree ("../bin");
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
      Package_Files : constant array (Positive range <>) of U.Unbounded_String :=
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
         U.To_Unbounded_String ("docs/testing.md"),
         U.To_Unbounded_String ("docs/building.md"),
         U.To_Unbounded_String ("docs/releasing.md"),
         U.To_Unbounded_String ("docs/ai/project-map.md"),
         U.To_Unbounded_String ("docs/ai/package-contracts.md"),
         U.To_Unbounded_String ("docs/ai/invariants.md"),
         U.To_Unbounded_String ("docs/ai/workflows.md"),
         U.To_Unbounded_String ("docs/ai/prohibited-designs.md"),
         U.To_Unbounded_String ("resources/messages/catalog.txt"),
         U.To_Unbounded_String ("resources/messages/en/catalog.txt"),
         U.To_Unbounded_String ("resources/messages/da/catalog.txt")];

      function Hex_64 (Value : Interfaces.Unsigned_64) return String is
         Hex_Digits : constant String := "0123456789abcdef";
         Result     : String (1 .. 16);
         Work       : Interfaces.Unsigned_64 := Value;
      begin
         for Index in reverse Result'Range loop
            Result (Index) := Hex_Digits (Natural (Work mod 16) + 1);
            Work := Work / 16;
         end loop;
         return Result;
      end Hex_64;

      function Checksum (Path : String) return String is
         package SIO renames Ada.Streams.Stream_IO;
         File       : SIO.File_Type;
         Buffer     : Ada.Streams.Stream_Element_Array (1 .. 8192);
         Last       : Ada.Streams.Stream_Element_Offset;
         FNV_Offset : constant Interfaces.Unsigned_64 := 16#cbf29ce484222325#;
         FNV_Prime  : constant Interfaces.Unsigned_64 := 16#00000100000001b3#;
         Result     : Interfaces.Unsigned_64 := FNV_Offset;
      begin
         SIO.Open (File, SIO.In_File, Path);
         while not SIO.End_Of_File (File) loop
            SIO.Read (File, Buffer, Last);
            for Index in Buffer'First .. Last loop
               Result := (Result xor Interfaces.Unsigned_64 (Buffer (Index))) * FNV_Prime;
            end loop;
         end loop;
         SIO.Close (File);
         return Hex_64 (Result);
      exception
         when others =>
            if SIO.Is_Open (File) then
               SIO.Close (File);
            end if;
            return "0000000000000000";
      end Checksum;

      function Length_Of (Path : String) return Natural is
        (Natural (Dir.Size (Path)));

      procedure Add_Manifest_Line
        (Buffer : in out U.Unbounded_String;
         Path   : String)
      is
      begin
         U.Append
           (Buffer,
            Path & " bytes=" & Natural'Image (Length_Of (Dist & "/" & Path))
            & " fnv1a64=" & Checksum (Dist & "/" & Path)
            & ASCII.LF);
      end Add_Manifest_Line;

      procedure Require_Package_File (Path : String) is
      begin
         Files.Require_File (Dist & "/" & Path, "missing package file: " & Path);
         Require (Length_Of (Dist & "/" & Path) > 0, "empty package file: " & Path);
      end Require_Package_File;

      procedure Require_Manifest_Entry (Path : String) is
         Expected_Line : constant String :=
           Path & " bytes=" & Natural'Image (Length_Of (Dist & "/" & Path))
           & " fnv1a64=" & Checksum (Dist & "/" & Path);
      begin
         Require
           (Files.Has_Line (Dist & "/MANIFEST.txt", Expected_Line),
            "package manifest missing entry: " & Path);
      end Require_Manifest_Entry;

      function Manifest_Line_Count return Natural is
         Text   : constant String := File_Text (Dist & "/MANIFEST.txt");
         Breaks : constant Natural := Project_Tools.Text.Count (Text, "" & ASCII.LF);
      begin
         if Text'Length = 0 then
            return 0;
         elsif Text (Text'Last) = ASCII.LF then
            return Breaks;
         else
            return Breaks + 1;
         end if;
      end Manifest_Line_Count;

      procedure Copy_Package_File (Path : String) is
         Source : constant String :=
           (if Path = "bin/awk" then "../bin/awk" else "../" & Path);
      begin
         Copy_File (Source, Dist & "/" & Path);
      end Copy_Package_File;

      Manifest : U.Unbounded_String;
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
      Files.Write_Text_File (Dist & "/MANIFEST.txt", U.To_String (Manifest));
      Require_Package_File ("MANIFEST.txt");
      Require
        (File_Has (Dist & "/MANIFEST.txt", "fnv1a64="),
         "package manifest must include FNV-1a-64 checksum fields");
      Require
        (not File_Has (Dist & "/MANIFEST.txt", " checksum="),
         "package manifest must not use legacy checksum field");
      Require
        (Manifest_Line_Count = Package_Files'Length,
         "package manifest must contain one line per packaged file");
      for Path of Package_Files loop
         Require_Manifest_Entry (U.To_String (Path));
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
