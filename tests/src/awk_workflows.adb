with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Awk_Workflow_Catalogs;
with Awk_Workflow_Docs;
with Awk_Workflow_Metadata;
with Awk_Workflow_Packaging;
with Awk_Workflow_Source_Policy;
with Project_Tools.Alire;
with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Test_Fixtures;
with Project_Tools.Text;
with Project_Tools.Tree_Checks;

procedure Awk_Workflows is
   package CLI renames Ada.Command_Line;
   package Proc renames Project_Tools.Processes;
   package Files renames Project_Tools.Files;
   package Fixtures renames Project_Tools.Test_Fixtures;
   package Text renames Project_Tools.Text;
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

   procedure Release_Build is
   begin
      Project_Tools.Alire.Run_Build (Directory => Root, Release_Mode => True);
      Project_Tools.Alire.Run_Build (Directory => ".", Release_Mode => True);
   end Release_Build;

   procedure Run_AUnit is
   begin
      Project_Tools.Release_Checks.Run
        ("./bin/awk_tests_main", ".", "./bin/awk_tests_main", No_Arguments);
   end Run_AUnit;

   procedure Test is
   begin
      Project_Tools.Alire.Run_Build (Directory => ".");
      Run_AUnit;
   end Test;

   procedure Require_Clean_Repository is
   begin
      Project_Tools.Release_Checks.Require_Clean_Git_Worktree
        ("awk", Root, Quiet => True);
   end Require_Clean_Repository;





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

   procedure Core_Quality_Gates is
   begin
      Awk_Workflow_Metadata.Run;
      Awk_Workflow_Docs.Run;
      Awk_Workflow_Catalogs.Run;
      Conformance;
      Exit_Status_Drift;
      Option_Drift;
      Awk_Workflow_Source_Policy.Package_Manifest_Policy;
      Awk_Workflow_Source_Policy.Run;
   end Core_Quality_Gates;

   procedure Verify is
   begin
      Build;
      Test;
      Core_Quality_Gates;
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
      Awk_Workflow_Docs.Run;
   elsif Command = "clean" then
      Clean;
   elsif Command = "package" then
      Awk_Workflow_Packaging.Run;
      Build_Output_Policy;
   elsif Command = "release" then
      Require_Clean_Repository;
      Release_Build;
      Run_AUnit;
      Core_Quality_Gates;
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
      CLI.Set_Exit_Status (CLI.Failure);
   when Error : others =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "unexpected workflow failure: " & Ada.Exceptions.Exception_Information (Error));
      CLI.Set_Exit_Status (CLI.Failure);
end Awk_Workflows;
