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
with Project_Tools.Files;
with Project_Tools.Processes;

procedure Awk_Workflows is
   package CLI renames Ada.Command_Line;
   package Dir renames Ada.Directories;
   package Proc renames Project_Tools.Processes;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;
   use type Interfaces.Unsigned_64;

   Root : constant String := "..";
   Alr  : constant String := Proc.Locate_Command ("alr");
   Env  : constant String := Proc.Locate_Command ("env");
   Git  : constant String := Proc.Locate_Command ("git");

   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Fail (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Message);
      CLI.Set_Exit_Status (CLI.Failure);
      raise Program_Error;
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

      Home : constant String := Derived_Home;
      Path : constant String := Value_Or_Empty ("PATH");
   begin
      Require (Alr /= "", "alr executable not found");
      if Env /= "" and then Home /= "" then
         declare
            Args : constant GNAT.OS_Lib.Argument_List :=
              (if Release_Mode
               then
                 [new String'("-i"),
                  new String'("HOME=" & Home),
                  new String'("XDG_DATA_HOME=" & Home & "/.local/share"),
                  new String'("XDG_CONFIG_HOME=" & Home & "/.config"),
                  new String'("PATH=" & Path),
                  new String'(Alr),
                  new String'("-n"),
                  new String'("build"),
                  new String'("--release"),
                  new String'("--profiles=*=release")]
               else
                 [new String'("-i"),
                  new String'("HOME=" & Home),
                  new String'("XDG_DATA_HOME=" & Home & "/.local/share"),
                  new String'("XDG_CONFIG_HOME=" & Home & "/.config"),
                  new String'("PATH=" & Path),
                  new String'(Alr),
                  new String'("-n"),
                  new String'("build"),
                  new String'("--development")]);
         begin
            if Proc.Run_Status ("alr build", Directory, Env, Args) /= 0 then
               Fail ("alr build failed in " & Directory);
            end if;
         end;
      else
         declare
            Args : constant GNAT.OS_Lib.Argument_List :=
              (if Release_Mode
               then [new String'("-n"), new String'("build"), new String'("--release"),
                     new String'("--profiles=*=release")]
               else [new String'("-n"), new String'("build"), new String'("--development")]);
         begin
            if Proc.Run_Status ("alr build", Directory, Alr, Args) /= 0 then
               Fail ("alr build failed in " & Directory);
            end if;
         end;
      end if;
   end Run_Alr_Build;

   procedure Run_Binary (Directory, Program : String) is
      Args : GNAT.OS_Lib.Argument_List (1 .. 0);
   begin
      if Proc.Run_Status (Program, Directory, Program, Args) /= 0 then
         Fail (Program & " failed");
      end if;
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
      Output : Proc.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("status"), new String'("--porcelain")];
   begin
      Require (Git /= "", "git executable not found");
      if Proc.Run_Status ("git status --porcelain", Root, Git, Args, Output, Quiet => True) /= 0 then
         Fail ("git status failed");
      end if;
      Require (U.Length (Output) = 0, "release requires a clean git working tree");
   end Require_Clean_Repository;

   function File_Text (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Buffer : U.Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         U.Append (Buffer, Ada.Text_IO.Get_Line (File));
         if not Ada.Text_IO.End_Of_File (File) then
            U.Append (Buffer, ASCII.LF);
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return U.To_String (Buffer);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return "";
   end File_Text;

   function Contains (Text, Pattern : String) return Boolean is
   begin
      if Pattern'Length = 0 then
         return True;
      end if;
      if Text'Length < Pattern'Length then
         return False;
      end if;
      for Index in Text'First .. Text'Last - Pattern'Length + 1 loop
         if Text (Index .. Index + Pattern'Length - 1) = Pattern then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

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
      procedure Require_Path (Path : String) is
      begin
         Require (Dir.Exists (Path), "missing required documentation: " & Path);
      end Require_Path;
   begin
      Require_Path ("../README.md");
      Require_Path ("../CHANGELOG.md");
      Require_Path ("../CONTRIBUTING.md");
      Require_Path ("../SECURITY.md");
      Require_Path ("../LICENSE");
      Require_Path ("../docs/quickstart.md");
      Require_Path ("../docs/command-line-reference.md");
      Require_Path ("../docs/compatibility.md");
      Require_Path ("../docs/architecture.md");
      Require_Path ("../docs/diagnostics.md");
      Require_Path ("../docs/localization.md");
      Require_Path ("../docs/testing.md");
      Require_Path ("../docs/building.md");
      Require_Path ("../docs/releasing.md");
      Require_Path ("../docs/ai/project-map.md");
      Require_Path ("../docs/ai/package-contracts.md");
      Require_Path ("../docs/ai/invariants.md");
      Require_Path ("../docs/ai/workflows.md");
      Require_Path ("../docs/ai/prohibited-designs.md");
      Require
        (Contains (File_Text ("../README.md"), "does not claim complete POSIX conformance"),
         "README must not claim full POSIX conformance");
      Require
        (Contains (File_Text ("../README.md"), "./bin/awk_tests_main"),
         "README must document the current AUnit executable");
      Require
        (Contains (File_Text ("../README.md"), "--color=auto|always|never"),
         "README must document color policy");
      Require
        (Contains (File_Text ("../README.md"), "Windows"),
         "README must include Windows quoting guidance");
      Require
        (Contains (File_Text ("../alire.toml"), "licenses = ""MIT"""),
         "root crate must declare MIT license");
      Require
        (Contains (File_Text ("alire.toml"), "licenses = ""MIT"""),
         "tests crate must declare MIT license");
      Require
        (Contains (File_Text ("../LICENSE"), "MIT License"),
         "LICENSE must contain MIT license text");
      Require
        (Contains (File_Text ("../docs/command-line-reference.md"), "-f program-file"),
         "command-line reference must document program-file invocation");
      Require
        (Contains (File_Text ("../docs/command-line-reference.md"), "Runtime assignment operands"),
         "command-line reference must document runtime assignment operands");
      Require
        (Contains (File_Text ("../docs/command-line-reference.md"),
                   "Supports_Positional_Runtime_Assignments = True"),
         "command-line reference must document positional assignment capability");
      Require
        (Contains (File_Text ("../docs/architecture.md"), "Awk_CLI.Execution"),
         "architecture docs must document execution adapter isolation");
      Require
        (Contains (File_Text ("../docs/architecture.md"), "Invocation_Context"),
         "architecture docs must document testable invocation context");
      Require
        (Contains (File_Text ("../docs/compatibility.md"),
                   "No current compatibility-registry entries are active"),
         "compatibility docs must state the empty active registry");
      Require
        (Contains (File_Text ("../docs/compatibility.md"), "Test reference"),
         "compatibility docs must include test references");
      Require
        (Contains (File_Text ("../docs/compatibility.md"), "Status"),
         "compatibility docs must include status names");
      Require
        (Contains (File_Text ("../docs/compatibility.md"), "Source"),
         "compatibility docs must include limitation source");
      Require
        (Contains (File_Text ("../docs/diagnostics.md"), "destination-aware terminal detection"),
         "diagnostics docs must document destination-aware terminal styling");
      Require
        (Contains (File_Text ("../docs/diagnostics.md"), "open failures from read failures"),
         "diagnostics docs must document open/read failure distinction");
      Require
        (Contains (File_Text ("../docs/architecture.md"), "main input is callback-driven"),
         "architecture docs must document memory-oriented host integration");
      Require
        (Contains (File_Text ("../docs/architecture.md"), "AWK record splitting"),
         "architecture docs must document awklib text streaming callbacks");
      Require
        (Contains (File_Text ("../docs/architecture.md"),
                   "Supports_Redirection_Append_Mode = True"),
         "architecture docs must document append redirection capability");
      Require
        (Contains (File_Text ("../docs/architecture.md"),
                   "Supports_Streaming_Execution = True"),
         "architecture docs must document streaming capability");
      Require
        (Contains (File_Text ("../docs/testing.md"), "structured diagnostic"),
         "testing docs must mention structured diagnostic assertions");
      Require
        (Contains (File_Text ("../docs/testing.md"), "awk_tests-cli_options"),
         "testing docs must document subsystem test packages");
      Require
        (Contains (File_Text ("../docs/testing.md"), "conformance manifest"),
         "testing docs must mention conformance manifest validation");
      Require
        (Contains (File_Text ("../docs/testing.md"), "Alire install-boundary"),
         "testing docs must mention install-boundary validation");
      Require
        (Contains (File_Text ("../docs/testing.md"), "FNV-1a-64"),
         "testing docs must mention release checksum validation");
      Require
        (Contains (File_Text ("../docs/building.md"), "install boundary"),
         "building docs must mention install boundary verification");
      Require
        (Contains (File_Text ("../docs/releasing.md"), "--release --profiles=*=release"),
         "release docs must document release-profile builds");
      Require
        (Contains (File_Text ("../docs/releasing.md"), "clean git working tree"),
         "release docs must document clean-tree enforcement");
      Require
        (Contains (File_Text ("../docs/releasing.md"), "FNV-1a-64"),
         "release docs must document manifest checksum algorithm");
      Require
        (Contains (File_Text ("../docs/releasing.md"), "temporary prefix"),
         "release docs must document temporary install-prefix validation");
      Put_Info ("documentation checks passed");
   end Docs;

   procedure Metadata is
      Root_Alire  : constant String := File_Text ("../alire.toml");
      Tests_Alire : constant String := File_Text ("alire.toml");
      Root_Gpr    : constant String := File_Text ("../awk.gpr");
      Tests_Gpr   : constant String := File_Text ("awk_tests.gpr");
   begin
      Require (Contains (Root_Alire, "name = ""awk"""),
               "root crate name must be awk");
      Require (Contains (Root_Alire, "executables = [""awk""]"),
               "root crate must install executable awk");
      Require (Contains (Root_Alire, "project-files = [""awk.gpr""]"),
               "root crate must use awk.gpr");
      Require (Contains (Root_Alire, "awklib = "),
               "root crate must depend on awklib");
      Require (Contains (Root_Alire, "terminal_styles = "),
               "root crate must depend on terminal_styles");
      Require (Contains (Root_Alire, "messages = "),
               "root crate must depend on messages");
      Require (Contains (Tests_Alire, "name = ""awk_tests"""),
               "tests crate name must be awk_tests");
      Require (Contains (Tests_Alire, "awk = "),
               "tests crate must depend on awk");
      Require (Contains (Tests_Alire, "aunit = "),
               "tests crate must depend on AUnit");
      Require (Contains (Tests_Alire, "project_tools = "),
               "tests crate must depend on project_tools");
      Require (Contains (Tests_Alire, "awk = { path = "".."" }"),
               "tests crate must pin awk relatively");
      Require (Contains (Root_Gpr, "-gnat2022"),
               "root project must compile with Ada 2022");
      Require (Contains (Tests_Gpr, "-gnat2022"),
               "tests project must compile with Ada 2022");
      Require (Contains (Root_Gpr, "for Main use (""awk.adb"")"),
               "root project main must be awk.adb");
      Require (Contains (Tests_Gpr, "awk_workflows.adb"),
               "tests project must build workflow executable");
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
         Require (Contains (Manifest, Line), "conformance manifest missing case: " & Id);
         Require (Dir.Exists ("conformance/" & Case_File),
                  "conformance case file missing: " & Case_File);
         Require (Dir.Exists ("conformance/" & Expected),
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
      function Is_Generated_Or_Dependency_Path (Path : String) return Boolean is
      begin
         return Contains (Path, "/alire/")
           or else Contains (Path, "/obj/")
           or else Contains (Path, "/bin/")
           or else Contains (Path, "/dist/")
           or else Contains (Path, "/config/");
      end Is_Generated_Or_Dependency_Path;

      function Allowed_Path (Path, Allowed : String) return Boolean is
      begin
         return Path = Allowed;
      end Allowed_Path;

      function First_Workflow_Script return String is
         All_Files : constant Files.Path_List := Files.List_Tree ("..", "*");
      begin
         for Path of All_Files loop
            declare
               Name : constant String := U.To_String (Path);
           begin
               if not Is_Generated_Or_Dependency_Path (Name)
                 and then not Contains (Name, "/.git/")
                 and then
                   (Contains (Name, ".sh")
                    or else Contains (Name, ".py")
                    or else Contains (Name, ".ps1")
                    or else Contains (Name, "Makefile")
                    or else Contains (Name, ".js"))
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
               if Contains (File_Text (Name), Pattern)
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
               if Contains (File_Text (Name), Pattern)
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
   begin
      Require
        (Contains (File_Text ("../src/library/awk_cli-execution.adb"), "with Awklib"),
         "execution adapter must bridge to awklib");
      Require
        (First_Unexpected_Dependency ("with Awklib", "../src/library/awk_cli-execution.adb") = "",
         "only execution adapter may depend on awklib");
      Require
        (Contains (File_Text ("../src/library/awk_cli-localization.adb"), "with Messages"),
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
        (Contains (File_Text ("../src/library/awk_cli-output.adb"), "with Terminal_Styles"),
         "presentation layer must bridge to terminal_styles");
      Require
        (First_Unexpected_Dependency ("with Terminal_Styles", "../src/library/awk_cli-output.adb") = "",
         "only presentation layer may depend on terminal_styles");
      Require
        (not Contains (File_Text ("../src/library/awk_cli-output.adb"), "Character'Val (27)"),
         "presentation layer must not emit handwritten ANSI escapes");
      Require
        (not Files.Any_File_Contains ("../src", "gawk"),
         "production source must not invoke or reference external gawk fallback");
      Require
        (not Files.Any_File_Contains ("../src", "mawk"),
         "production source must not invoke or reference external mawk fallback");
      Require
        (not Files.Any_File_Contains ("../src", "nawk"),
         "production source must not invoke or reference external nawk fallback");
      Require
        (Files.File_Exists ("src/awk_tests-cli_options.ads")
         and then Files.File_Exists ("src/awk_tests-cli_options.adb"),
         "option parser tests must live in a subsystem test package");
      Require
        (Files.File_Exists ("src/awk_tests-program_sources.ads")
         and then Files.File_Exists ("src/awk_tests-program_sources.adb"),
         "program source tests must live in a subsystem test package");
      Require
        (Files.File_Exists ("src/awk_tests-operands.ads")
         and then Files.File_Exists ("src/awk_tests-operands.adb"),
         "operand tests must live in a subsystem test package");
      Require
        (Files.File_Exists ("src/awk_tests-diagnostics.ads")
         and then Files.File_Exists ("src/awk_tests-diagnostics.adb"),
         "diagnostic tests must live in a subsystem test package");
      Require
        (Files.File_Exists ("src/awk_tests-localization.ads")
         and then Files.File_Exists ("src/awk_tests-localization.adb"),
         "localization tests must live in a subsystem test package");
      Require
        (Files.File_Exists ("src/awk_tests-redirections.ads")
         and then Files.File_Exists ("src/awk_tests-redirections.adb"),
         "redirection tests must live in a subsystem test package");
      Require
        (Files.File_Exists ("src/awk_tests-execution.ads")
         and then Files.File_Exists ("src/awk_tests-execution.adb"),
         "execution tests must live in a subsystem test package");
      Require
        (Files.File_Exists ("src/awk_tests-process.ads")
         and then Files.File_Exists ("src/awk_tests-process.adb"),
         "process tests must live in a subsystem test package");
      Require
        (Files.File_Exists ("src/awk_tests-inputs.ads")
         and then Files.File_Exists ("src/awk_tests-inputs.adb"),
         "input tests must live in a subsystem test package");
      Require
        (Files.File_Exists ("src/awk_tests-environment.ads")
         and then Files.File_Exists ("src/awk_tests-environment.adb"),
         "environment tests must live in a subsystem test package");
      Require
        (Contains (File_Text ("src/awk_tests-suite.adb"), "Awk_Tests.CLI_Options.Case_Type"),
         "aggregate suite must include CLI option subsystem tests");
      Require
        (Contains (File_Text ("src/awk_tests-suite.adb"), "Awk_Tests.Diagnostics.Case_Type"),
         "aggregate suite must include diagnostic subsystem tests");
      Require
        (Contains (File_Text ("src/awk_tests-suite.adb"), "Awk_Tests.Localization.Case_Type"),
         "aggregate suite must include localization subsystem tests");
      Require
        (Contains (File_Text ("src/awk_tests-suite.adb"), "Awk_Tests.Operands.Case_Type"),
         "aggregate suite must include operand subsystem tests");
      Require
        (Contains (File_Text ("src/awk_tests-suite.adb"), "Awk_Tests.Program_Sources.Case_Type"),
         "aggregate suite must include program source subsystem tests");
      Require
        (Contains (File_Text ("src/awk_tests-suite.adb"), "Awk_Tests.Redirections.Case_Type"),
         "aggregate suite must include redirection subsystem tests");
      Require
        (Contains (File_Text ("src/awk_tests-suite.adb"), "Awk_Tests.Execution.Case_Type"),
         "aggregate suite must include execution subsystem tests");
      Require
        (Contains (File_Text ("src/awk_tests-suite.adb"), "Awk_Tests.Process.Case_Type"),
         "aggregate suite must include process subsystem tests");
      Require
        (Contains (File_Text ("src/awk_tests-suite.adb"), "Awk_Tests.Inputs.Case_Type"),
         "aggregate suite must include input subsystem tests");
      Require
        (Contains (File_Text ("src/awk_tests-suite.adb"), "Awk_Tests.Environment.Case_Type"),
         "aggregate suite must include environment subsystem tests");
      Require
        (Contains (File_Text ("src/awk_workflows.adb"), "--release"),
         "release workflow must use Alire release builds");
      Require
        (Contains (File_Text ("src/awk_workflows.adb"), "status"),
         "release workflow must check git status");
      Require
        (not Contains (File_Text ("src/awk_workflows.adb"), "release"") then" & ASCII.LF &
                                                     "      Verify;"),
         "release workflow must not reuse development verify gate");
      Require
        (First_Workflow_Script = "",
         "workflow logic must not use shell or scripting files: " & First_Workflow_Script);
      Put_Info ("source policy checks passed");
   end Source_Policy;

   procedure Install_Boundary is
      Prefix : constant String := "/tmp/awk-install-boundary";
      Output : Proc.Unbounded_String;
      Install_Args : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("-n"),
         new String'("install"),
         new String'("--prefix=" & Prefix)];
      Version_Args : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--version")];
   begin
      Require (Alr /= "", "alr executable not found");
      if Dir.Exists (Prefix) then
         Dir.Delete_Tree (Prefix);
      end if;

      if Proc.Run_Status ("alr install", Root, Alr, Install_Args, Output, Quiet => True) /= 0 then
         Fail ("alr install failed");
      end if;

      Require (Dir.Exists (Prefix & "/bin/awk"), "installed awk executable missing");
      if Proc.Run_Status
          ("installed awk --version", Root, Prefix & "/bin/awk", Version_Args,
           Output, Quiet => True) /= 0
      then
         Fail ("installed awk executable failed");
      end if;
      Require (Contains (U.To_String (Output), "awk 0.1.0"),
               "installed awk version output is unexpected");

      if Dir.Exists (Prefix) then
         Dir.Delete_Tree (Prefix);
      end if;
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

   procedure Remove_If_Exists (Path : String) is
   begin
      if Dir.Exists (Path) then
         Dir.Delete_Tree (Path);
      end if;
   end Remove_If_Exists;

   procedure Clean is
   begin
      Remove_If_Exists ("../obj");
      Remove_If_Exists ("../bin");
      Remove_If_Exists ("obj");
      Remove_If_Exists ("bin");
      Put_Info ("cleaned build outputs");
   end Clean;

   procedure Copy_File (Source, Target : String) is
   begin
      if Dir.Exists (Target) then
         Dir.Delete_File (Target);
      end if;
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
         File         : SIO.File_Type;
         Buffer       : Ada.Streams.Stream_Element_Array (1 .. 8192);
         Last         : Ada.Streams.Stream_Element_Offset;
         FNV_Offset   : constant Interfaces.Unsigned_64 := 16#cbf29ce484222325#;
         FNV_Prime    : constant Interfaces.Unsigned_64 := 16#00000100000001b3#;
         Result       : Interfaces.Unsigned_64 := FNV_Offset;
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
         Require (Files.File_Exists (Dist & "/" & Path), "missing package file: " & Path);
         Require (Length_Of (Dist & "/" & Path) > 0, "empty package file: " & Path);
      end Require_Package_File;

      procedure Require_Manifest_Entry (Path : String) is
         Manifest_Text : constant String := File_Text (Dist & "/MANIFEST.txt");
         Expected_Line : constant String :=
           Path & " bytes=" & Natural'Image (Length_Of (Dist & "/" & Path))
           & " fnv1a64=" & Checksum (Dist & "/" & Path);
      begin
         Require
           (Contains (Manifest_Text, Expected_Line),
            "package manifest missing entry: " & Path);
      end Require_Manifest_Entry;

      function Manifest_Line_Count return Natural is
         Text   : constant String := File_Text (Dist & "/MANIFEST.txt");
         Result : Natural := 0;
      begin
         if Text'Length = 0 then
            return 0;
         end if;
         Result := 1;
         for Ch of Text loop
            if Ch = ASCII.LF then
               Result := Result + 1;
            end if;
         end loop;
         return Result;
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
      Remove_If_Exists ("../dist");
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
        (Contains (File_Text (Dist & "/MANIFEST.txt"), "fnv1a64="),
         "package manifest must include FNV-1a-64 checksum fields");
      Require
        (not Contains (File_Text (Dist & "/MANIFEST.txt"), " checksum="),
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
