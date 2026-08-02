with AUnit.Assertions;
with AUnit.Test_Cases;

with Ada.Containers;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Ada.Strings.Unbounded;

with Awk_CLI;
with Awk_CLI.Compatibility;
with Awk_CLI.Environment;
with Awk_CLI.Execution;
with Awk_Tests.CLI_Options;
with Awk_Tests.Diagnostics;
with Awk_Tests.Execution;
with Awk_Tests.Inputs;
with Awk_Tests.Localization;
with Awk_Tests.Operands;
with Awk_Tests.Program_Sources;
with Awk_Tests.Process;
with Awk_Tests.Redirections;

package body Awk_Tests.Suite is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;

   LF : constant String := [1 => ASCII.LF];

   type CLI_Case is new AUnit.Test_Cases.Test_Case with null record;
   overriding procedure Register_Tests (T : in out CLI_Case);

   use type Ada.Containers.Count_Type;
   use type Awk_CLI.Exit_Code;

   overriding function Name (T : CLI_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk cli");
   end Name;

   function File_Text (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Result : U.Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         U.Append (Result, Ada.Text_IO.Get_Line (File));
         if not Ada.Text_IO.End_Of_File (File) then
            U.Append (Result, LF);
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return U.To_String (Result);
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

   procedure Test_Context_Direct_Run (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print $2 }");
      Awk_CLI.Set_Standard_Input (Context, "one two" & LF & "three four" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "direct run succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "two" & LF & "four" & LF,
              "stdout is captured exactly");
      Assert (Awk_CLI.Standard_Error (Context) = "", "no diagnostics");
      Assert (not Awk_CLI.Has_Diagnostic (Context), "success has no structured diagnostic");
   end Test_Context_Direct_Run;

   procedure Test_Context_File_Run (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "-f");
      Awk_CLI.Add_Argument (Context, "prog.awk");
      Awk_CLI.Add_Argument (Context, "input.txt");
      Awk_CLI.Add_File (Context, "prog.awk", "{ print FILENAME, FNR, $1 }");
      Awk_CLI.Add_File (Context, "input.txt", "alpha beta" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "file-backed run succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "input.txt 1 alpha" & LF,
              "virtual file input reaches awklib");
   end Test_Context_File_Run;

   procedure Test_Context_Output_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""x"" }");
      Awk_CLI.Fail_Standard_Output (Context, True);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "stdout failure is host I/O");
      Assert (Awk_CLI.Standard_Output (Context) = "",
              "failed stdout is not reported as written output");
      Assert (Awk_CLI.Has_Diagnostic (Context), "stdout failure records a structured diagnostic");
      Assert
        (Awk_CLI.Last_Diagnostic_Message_Id (Context) = "awk.standard_output.write_failed",
         "structured diagnostic identifies stdout write failure");
      Assert (Awk_CLI.Last_Diagnostic_Category (Context) = "OUTPUT",
              "stdout write failure diagnostic is output-category");
   end Test_Context_Output_Failure;

   procedure Test_Context_Stderr_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "--bad");
      Awk_CLI.Fail_Standard_Error (Context, True);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "diagnostic stderr failure is host I/O");
      Assert (Awk_CLI.Standard_Error (Context) = "", "failed stderr is not reported as written");
      Assert (Awk_CLI.Has_Diagnostic (Context), "stderr failure preserves original diagnostic");
      Assert
        (Awk_CLI.Last_Diagnostic_Message_Id (Context) = "awk.usage.unknown_option",
         "stderr write failure does not replace the original diagnostic ID");
   end Test_Context_Stderr_Failure;

   procedure Test_Context_Auto_Color_Destinations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      No_Color_Found : constant Boolean := Ada.Environment_Variables.Exists ("NO_COLOR");
      No_Color_Value : constant String :=
        (if No_Color_Found then Ada.Environment_Variables.Value ("NO_COLOR") else "");
      Esc : constant String := [1 => Character'Val (27)];
   begin
      Ada.Environment_Variables.Clear ("NO_COLOR");
      begin
         declare
            Context : Awk_CLI.Invocation_Context;
            Status  : Awk_CLI.Exit_Code;
         begin
            Awk_CLI.Add_Argument (Context, "--color=auto");
            Awk_CLI.Add_Argument (Context, "--help");
            Awk_CLI.Set_Standard_Output_Terminal (Context, True);
            Awk_CLI.Set_Standard_Error_Terminal (Context, False);
            Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
            Status := Awk_CLI.Run (Context);
            Assert (Status = 0, "auto-color help succeeds");
            Assert
              (Contains (Awk_CLI.Standard_Output (Context), Esc & "["),
               "auto color styles terminal stdout help");
            Assert (Awk_CLI.Standard_Error (Context) = "", "help writes no stderr");
         end;

         declare
            Context : Awk_CLI.Invocation_Context;
            Status  : Awk_CLI.Exit_Code;
         begin
            Awk_CLI.Add_Argument (Context, "--bad-option");
            Awk_CLI.Set_Standard_Output_Terminal (Context, True);
            Awk_CLI.Set_Standard_Error_Terminal (Context, False);
            Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
            Status := Awk_CLI.Run (Context);
            Assert (Status = 2, "usage diagnostic exits with usage status");
            Assert
              (not Contains (Awk_CLI.Standard_Error (Context), Esc & "["),
               "auto color leaves non-terminal stderr diagnostic plain");
         end;

         declare
            Context : Awk_CLI.Invocation_Context;
            Status  : Awk_CLI.Exit_Code;
         begin
            Awk_CLI.Add_Argument (Context, "--bad-option");
            Awk_CLI.Set_Standard_Output_Terminal (Context, False);
            Awk_CLI.Set_Standard_Error_Terminal (Context, True);
            Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
            Status := Awk_CLI.Run (Context);
            Assert (Status = 2, "terminal stderr diagnostic exits with usage status");
            Assert
              (Contains (Awk_CLI.Standard_Error (Context), Esc & "["),
               "auto color styles terminal stderr diagnostic");
            Assert (Awk_CLI.Standard_Output (Context) = "", "diagnostic writes no stdout");
         end;
      exception
         when others =>
            if No_Color_Found then
               Ada.Environment_Variables.Set ("NO_COLOR", No_Color_Value);
            else
               Ada.Environment_Variables.Clear ("NO_COLOR");
            end if;
            raise;
      end;

      if No_Color_Found then
         Ada.Environment_Variables.Set ("NO_COLOR", No_Color_Value);
      else
         Ada.Environment_Variables.Clear ("NO_COLOR");
      end if;
   end Test_Context_Auto_Color_Destinations;

   procedure Test_Context_Environment (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ENVIRON[""AWK_TEST_ENV""] }");
      Awk_CLI.Add_Environment (Context, "AWK_TEST_ENV", "present");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "environment run succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "present" & LF,
              "environment entry reaches awklib");
   end Test_Context_Environment;

   procedure Test_Environment_Normalization (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Raw : Awk_CLI.Environment.Entry_Vectors.Vector;
   begin
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.Null_Unbounded_String,
            Value => U.To_Unbounded_String ("ignored")));
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.To_Unbounded_String ("AWK_DUP"),
            Value => U.To_Unbounded_String ("first")));
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.To_Unbounded_String ("AWK_OTHER"),
            Value => U.To_Unbounded_String ("kept")));
      Raw.Append
        (Awk_CLI.Environment.Env_Entry'
           (Name => U.To_Unbounded_String ("AWK_DUP"),
            Value => U.To_Unbounded_String ("second")));
      declare
         Normal : constant Awk_CLI.Environment.Entry_Vectors.Vector :=
           Awk_CLI.Environment.Normalize (Raw);
      begin
         Assert (Normal.Length = 2, "empty names are filtered and duplicates collapse");
         Assert (U.To_String (Normal.Element (1).Name) = "AWK_DUP",
                 "duplicate entry keeps original position");
         Assert (U.To_String (Normal.Element (1).Value) = "second",
                 "duplicate entry uses final value");
         Assert (U.To_String (Normal.Element (2).Name) = "AWK_OTHER",
                 "other entry order is preserved");
      end;
   end Test_Environment_Normalization;

   procedure Test_Context_Environment_Normalization_And_Confidentiality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "BEGIN { print ENVIRON[""AWK_DUP""]; print ENVIRON[""""] }");
      Awk_CLI.Add_Environment (Context, "AWK_DUP", "old-secret");
      Awk_CLI.Add_Environment (Context, "", "empty-secret");
      Awk_CLI.Add_Environment (Context, "AWK_DUP", "new-secret");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "normalized environment run succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "new-secret" & LF & LF,
              "duplicate env uses final value and empty env name is ignored");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument (Context, "{ print }");
      Awk_CLI.Add_Argument (Context, "missing.txt");
      Awk_CLI.Add_Environment (Context, "AWK_SECRET", "do-not-leak");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "missing input remains host I/O");
      Assert (not Contains (Awk_CLI.Standard_Error (Context), "do-not-leak"),
              "environment values are not emitted in unrelated diagnostics");
   end Test_Context_Environment_Normalization_And_Confidentiality;

   procedure Test_Context_Expressions_Regex_And_Builtins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument
        (Context,
         "BEGIN { print ENVIRON[""AWK_TEST_ENV""]; print length(""abcd"") } " &
         "/^[a-z]+ [0-9]+$/ { print $1, $2 + 3, substr($1, 2, 2) }");
      Awk_CLI.Add_Environment (Context, "AWK_TEST_ENV", "visible");
      Awk_CLI.Set_Standard_Input (Context, "abc 4" & LF & "NOPE" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "expression integration succeeds");
      Assert
        (Awk_CLI.Standard_Output (Context) =
         "visible" & LF & "4" & LF & "abc 7 bc" & LF,
         "ENVIRON, regex pattern, arithmetic, and builtins pass through awklib");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument
        (Context, "BEGIN { s = ""aa""; sub(/a|aa/, ""X"", s); print s }");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "leftmost-longest regex integration succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "X" & LF,
              "regex replacement uses awklib leftmost-longest selection");
   end Test_Context_Expressions_Regex_And_Builtins;

   procedure Test_Context_Auxiliary_Getline_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument
        (Context, "BEGIN { getline line < ""aux.txt""; print line }");
      Awk_CLI.Add_Argument (Context, "aux.txt");
      Awk_CLI.Add_File (Context, "aux.txt", "from aux" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "auxiliary getline integration succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "from aux" & LF,
              "getline < file uses files registered through the execution adapter");
   end Test_Context_Auxiliary_Getline_File;

   procedure Test_Context_Main_Getline_From_Begin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument
        (Context,
         "BEGIN { getline line; print FILENAME, FNR, NR, line }"
         & " { print ""main"", FNR, NR, $0 }");
      Awk_CLI.Add_Argument (Context, "-");
      Awk_CLI.Set_Standard_Input (Context, "first" & LF & "second" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "main-input getline from BEGIN succeeds");
      Assert
        (Awk_CLI.Standard_Output (Context) =
         "- 1 1 first" & LF & "main 2 2 second" & LF,
         "BEGIN getline shares the CLI main-input cursor");
   end Test_Context_Main_Getline_From_Begin;

   procedure Test_Context_Command_Getline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument
        (Context,
         "BEGIN { ""printf x"" | getline value; print value }");
      Awk_CLI.Add_Command_Output (Context, "printf x", "x");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "command getline succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "x" & LF,
              "command getline uses awklib command callback output");
   end Test_Context_Command_Getline;

   procedure Test_Context_Argv_Argc (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument
        (Context,
         "BEGIN { print ARGC; print ARGV[0]; print ARGV[1]; print ARGV[2]; print ARGV[3] }");
      Awk_CLI.Add_Argument (Context, "input.txt");
      Awk_CLI.Add_Argument (Context, "name=value");
      Awk_CLI.Add_Argument (Context, "-");
      Awk_CLI.Add_File (Context, "input.txt", "ignored" & LF);
      Awk_CLI.Set_Standard_Input (Context, "stdin" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "ARGV/ARGC run succeeds");
      Assert
        (Awk_CLI.Standard_Output (Context) =
           "4" & LF & "awk" & LF & "input.txt" & LF & "name=value" & LF & "-" & LF,
         "ARGV preserves operand spelling and order");
   end Test_Context_Argv_Argc;

   procedure Test_Context_Runtime_Assignment_Positions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument
        (Context,
         "BEGIN { print ""begin"", X } " &
         "{ print FILENAME, FNR, X, $0 } " &
         "END { print ""end"", X }");
      Awk_CLI.Add_Argument (Context, "first.txt");
      Awk_CLI.Add_Argument (Context, "X=42");
      Awk_CLI.Add_Argument (Context, "first.txt");
      Awk_CLI.Add_Argument (Context, "X=99");
      Awk_CLI.Add_File (Context, "first.txt", "one" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "runtime assignment run succeeds");
      Assert (Awk_CLI.Execution.Supports_Positional_Runtime_Assignments,
              "execution adapter exposes positional assignment support");
      Assert
        (Awk_CLI.Standard_Output (Context) =
         "begin " & LF &
         "first.txt 1  one" & LF &
         "first.txt 1 42 one" & LF &
         "end 99" & LF,
         "runtime assignments are applied at operand positions");
   end Test_Context_Runtime_Assignment_Positions;

   procedure Test_Compatibility_Registry (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Docs        : constant String := File_Text ("../docs/compatibility.md");
      Conformance : constant String := File_Text ("conformance/manifest/cases.txt");
   begin
      Assert (Awk_CLI.Compatibility.Count = 0, "registry has no active limitation entries");
      Assert (not Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-GETLINE-001"),
              "main-input getline from BEGIN is no longer a compatibility limitation");
      Assert (not Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-GETLINE-002"),
              "command getline is no longer a compatibility limitation");
      Assert (not Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-UTF8-001"),
              "malformed UTF-8 is no longer a compatibility limitation");
      Assert (not Awk_CLI.Compatibility.Has_Id ("AWK-COMPAT-PRINTF-001"),
              "printf %c field width is no longer a compatibility limitation");
      Assert
        (Contains (Docs, "No current compatibility-registry entries are active"),
         "compatibility docs state the empty registry");
      Assert
        (Contains (Conformance, "AWK-CONF-GETLINE-001|Supported"),
         "conformance manifest marks command getline supported");
   end Test_Compatibility_Registry;

   procedure Test_Conformance_Manifest (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Manifest : constant String := File_Text ("conformance/manifest/cases.txt");

      procedure Require_Case
        (Id       : String;
         Status   : String;
         Case_File : String;
         Expected : String;
         Reference : String)
      is
         Line : constant String :=
           Id & "|" & Status & "|" & Case_File & "|" & Expected & "|" & Reference;
      begin
         Assert (Contains (Manifest, Line), "manifest contains " & Id);
         Assert (Ada.Directories.Exists ("conformance/" & Case_File),
                 "case file exists for " & Id);
         Assert (Ada.Directories.Exists ("conformance/" & Expected),
                 "expected file exists for " & Id);
         Assert (File_Text ("conformance/" & Case_File) /= "",
                 "case file is non-empty for " & Id);
         Assert (File_Text ("conformance/" & Expected) /= "",
                 "expected file is non-empty for " & Id);
      end Require_Case;
   begin
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
   end Test_Conformance_Manifest;

   overriding procedure Register_Tests (T : in out CLI_Case) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Context_Direct_Run'Access, "context direct run");
      Registration.Register_Routine (T, Test_Context_File_Run'Access, "context file run");
      Registration.Register_Routine (T, Test_Context_Output_Failure'Access, "context output failure");
      Registration.Register_Routine (T, Test_Context_Stderr_Failure'Access, "context stderr failure");
      Registration.Register_Routine
        (T, Test_Context_Auto_Color_Destinations'Access, "context auto color destinations");
      Registration.Register_Routine (T, Test_Context_Environment'Access, "context environment");
      Registration.Register_Routine (T, Test_Environment_Normalization'Access, "environment normalization");
      Registration.Register_Routine
        (T, Test_Context_Environment_Normalization_And_Confidentiality'Access,
         "context environment normalization confidentiality");
      Registration.Register_Routine
        (T, Test_Context_Expressions_Regex_And_Builtins'Access,
         "context expressions regex builtins");
      Registration.Register_Routine
        (T, Test_Context_Auxiliary_Getline_File'Access,
         "context auxiliary getline file");
      Registration.Register_Routine
        (T, Test_Context_Main_Getline_From_Begin'Access,
         "context main getline from BEGIN");
      Registration.Register_Routine
        (T, Test_Context_Command_Getline'Access,
         "context command getline");
      Registration.Register_Routine (T, Test_Context_Argv_Argc'Access, "context ARGV/ARGC");
      Registration.Register_Routine
        (T, Test_Context_Runtime_Assignment_Positions'Access,
         "context runtime assignment positions");
      Registration.Register_Routine (T, Test_Compatibility_Registry'Access, "compatibility registry");
      Registration.Register_Routine (T, Test_Conformance_Manifest'Access, "conformance manifest");
   end Register_Tests;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite := new AUnit.Test_Suites.Test_Suite;
   begin
      pragma Warnings (Off, "use of an anonymous access type allocator");
      Result.Add_Test (new Awk_Tests.CLI_Options.Case_Type);
      Result.Add_Test (new Awk_Tests.Diagnostics.Case_Type);
      Result.Add_Test (new Awk_Tests.Execution.Case_Type);
      Result.Add_Test (new Awk_Tests.Inputs.Case_Type);
      Result.Add_Test (new Awk_Tests.Localization.Case_Type);
      Result.Add_Test (new Awk_Tests.Operands.Case_Type);
      Result.Add_Test (new Awk_Tests.Program_Sources.Case_Type);
      Result.Add_Test (new Awk_Tests.Process.Case_Type);
      Result.Add_Test (new Awk_Tests.Redirections.Case_Type);
      Result.Add_Test (new CLI_Case);
      pragma Warnings (On, "use of an anonymous access type allocator");
      return Result;
   end Suite;
end Awk_Tests.Suite;
