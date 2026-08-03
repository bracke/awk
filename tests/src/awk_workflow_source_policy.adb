with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Awk_Catalog_Policy;
with Awk_Workflow_Packaging;
with Project_Tools.Ada_Source;
with Project_Tools.AUnit_Checks;
with Project_Tools.Files;
with Project_Tools.Release_Checks;
with Project_Tools.Test_Fixtures;
with Project_Tools.Text;

package body Awk_Workflow_Source_Policy is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package Fixtures renames Project_Tools.Test_Fixtures;
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
         for Index in 1 .. Awk_Workflow_Packaging.File_Count loop
            if Awk_Workflow_Packaging.File_Path (Index) = Path then
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
      for Index in 1 .. Awk_Workflow_Packaging.File_Count loop
         declare
            Path : constant String := Awk_Workflow_Packaging.File_Path (Index);
         begin
            if Path /= "bin/awk" then
               Files.Require_File ("../" & Path,
                                   "packaged source file missing: " & Path);
            end if;
         end;
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

   procedure Run is
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
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            "Ada.Environment_Variables",
            Allowed_Files =>
              [U.To_Unbounded_String ("../src/library/awk_cli-platform.adb")]) = "",
         "process environment access must stay in platform adapter");
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
      Files.Require_Contains
        ("../src/library/awk_cli-platform.ads",
         "This is not a system-AWK fallback and must not parse AWK source.",
         "platform command runner must document callback-only ownership",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-live_context_callbacks.adb",
         "Only awklib reaches this callback after parsing/evaluating",
         "live command callback must document awklib ownership",
         Quiet => True);
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
      Files.Require_Contains
        ("../src/library/awk_cli-inputs-live.adb",
         "U.Slice (State.Active_Content",
         "in-memory live input chunking must avoid full-content copies",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-inputs-live.adb",
         [U.To_Unbounded_String ("U.To_String (State.Active_Content)")],
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
        ("src/awk_tests-process_support.adb", "with Project_Tools.Test_Fixtures",
         "process fixture file reads must use project_tools directly", Quiet => True);
      Files.Require_Contains
        ("src/awk_tests-localization.adb", "with Project_Tools.Test_Fixtures",
         "fixture file reads must use project_tools directly", Quiet => True);
      Files.Require_Contains
        ("src/awk_tests-compatibility.adb", "with Project_Tools.Test_Fixtures",
         "fixture file reads must use project_tools directly", Quiet => True);
      Files.Require_Contains
        ("src/awk_workflows.adb", "Release_Mode => True",
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
      Files.Require_Contains
        ("../.github/workflows/ci.yml",
         "os: [ubuntu-latest, macos-15-intel, windows-latest]",
         "CI workflow must include native Linux, macOS, and Windows build/test coverage",
         Quiet => True);
      Require
        (not Files.File_Contains ("src/awk_workflows.adb", "release"") then" & ASCII.LF &
                                             "      Verify;"),
         "release workflow must not reuse development verify gate");
      Require
        (Workflow_Script = "",
         "workflow logic must not use shell or scripting files: " & Workflow_Script);
      Put_Info ("source policy checks passed");
   end Run;
end Awk_Workflow_Source_Policy;
