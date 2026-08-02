with AUnit.Assertions;
with AUnit.Test_Cases;

with Ada.Containers;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Ada.Strings.Unbounded;

with GNAT.Expect;
with GNAT.OS_Lib;

with Awk_CLI;
with Awk_CLI.Compatibility;
with Awk_CLI.Environment;
with Awk_CLI.Execution;
with Project_Tools.Processes;
with Awk_Tests.CLI_Options;
with Awk_Tests.Diagnostics;
with Awk_Tests.Execution;
with Awk_Tests.Localization;
with Awk_Tests.Operands;
with Awk_Tests.Program_Sources;
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

   procedure Write_Text_File (Path, Content : String) is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Content);
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Write_Text_File;

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

   procedure Test_Context_Standard_Input_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print }");
      Awk_CLI.Fail_Standard_Input (Context, True);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "stdin failure is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot read standard input"),
              "stdin diagnostic is rendered");
   end Test_Context_Standard_Input_Failure;

   procedure Test_Context_Named_File_Does_Not_Read_Stdin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print $1 }");
      Awk_CLI.Add_Argument (Context, "input.txt");
      Awk_CLI.Add_File (Context, "input.txt", "file data" & LF);
      Awk_CLI.Fail_Standard_Input (Context, True);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "named-file input does not require stdin");
      Assert (Awk_CLI.Standard_Output (Context) = "file" & LF,
              "named-file input still reaches awklib");
   end Test_Context_Named_File_Does_Not_Read_Stdin;

   procedure Test_Context_Program_File_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "-f");
      Awk_CLI.Add_Argument (Context, "missing.awk");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "missing program file is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot open program file"),
              "program file open diagnostic is rendered");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument (Context, "-f");
      Awk_CLI.Add_Argument (Context, "unreadable.awk");
      Awk_CLI.Add_File (Context, "unreadable.awk", "", Readable => False);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "unreadable program file is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot read program file"),
              "program file read diagnostic is rendered");
   end Test_Context_Program_File_Failure;

   procedure Test_Context_Input_File_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print }");
      Awk_CLI.Add_Argument (Context, "missing.txt");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "missing input file is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot open input file"),
              "input file open diagnostic is rendered");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""begin"" } { print }");
      Awk_CLI.Add_Argument (Context, "missing.txt");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "lazy missing input file is still host I/O");
      Assert (Awk_CLI.Standard_Output (Context) = "begin" & LF,
              "BEGIN output is emitted before lazy input open failure");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot open input file"),
              "lazy input file open diagnostic is rendered");

      Awk_CLI.Clear (Context);
      Awk_CLI.Add_Argument (Context, "{ print }");
      Awk_CLI.Add_Argument (Context, "unreadable.txt");
      Awk_CLI.Add_File (Context, "unreadable.txt", "", Readable => False);
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "unreadable input file is host I/O");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "cannot read input file"),
              "input file read diagnostic is rendered");
   end Test_Context_Input_File_Failure;

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

   procedure Test_Context_Repeated_Stdin (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print FILENAME ""="" $0 }");
      Awk_CLI.Add_Argument (Context, "-");
      Awk_CLI.Add_Argument (Context, "-");
      Awk_CLI.Set_Standard_Input (Context, "one" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "repeated stdin succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "-=one" & LF,
              "second stdin operand observes end of file");
   end Test_Context_Repeated_Stdin;

   procedure Test_Context_Assignment_Only_Uses_Implicit_Stdin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print FILENAME ""="" $0 }");
      Awk_CLI.Add_Argument (Context, "X=not-applied-by-cli");
      Awk_CLI.Set_Standard_Input (Context, "implicit" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "assignment-only operands still use implicit stdin");
      Assert (Awk_CLI.Standard_Output (Context) = "=implicit" & LF,
              "implicit stdin keeps awklib's empty FILENAME behavior");
   end Test_Context_Assignment_Only_Uses_Implicit_Stdin;

   procedure Test_Context_Mixed_Input_Order_And_Spelling
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "{ print FILENAME "":"" FNR "":"" $0 }");
      Awk_CLI.Add_Argument (Context, "-");
      Awk_CLI.Add_Argument (Context, "dir/input name.txt");
      Awk_CLI.Add_Argument (Context, "-");
      Awk_CLI.Add_File (Context, "dir/input name.txt", "file one" & LF & "file two" & LF);
      Awk_CLI.Set_Standard_Input (Context, "stdin one" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "mixed stdin and named file input succeeds");
      Assert
        (Awk_CLI.Standard_Output (Context) =
           "-:1:stdin one" & LF &
           "dir/input name.txt:1:file one" & LF &
           "dir/input name.txt:2:file two" & LF,
         "input ordering and original filename spelling are preserved");
   end Test_Context_Mixed_Input_Order_And_Spelling;

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

   procedure Test_Process_Version (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--version")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk --version",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process version exits successfully");
      Assert (Contains (U.To_String (Output), "awk 0.1.0"), "process version includes awk version");
      Assert (Contains (U.To_String (Output), "awklib 0.1.0"), "process version includes awklib version");
   end Test_Process_Version;

   procedure Test_Process_Direct_File_Input (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk direct file input",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process direct file input exits successfully");
      Assert (U.To_String (Output) = "two" & LF & "four" & LF & LF,
              "process direct file input output");
   end Test_Process_Direct_File_Input;

   procedure Test_Process_Dash_Filename_After_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/-dash-input.txt";
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("--"),
         new String'("{ print FILENAME "":"" $1 }"),
         new String'(Target)];
      Status : Integer;
   begin
      Write_Text_File ("../" & Target, "dash data" & LF);
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process dash filename",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "dash-leading filename exits successfully after --");
      Assert
        (Contains (U.To_String (Output), Target & ":dash"),
         "dash-leading filename is treated as an operand");
      if Ada.Directories.Exists ("../" & Target) then
         Ada.Directories.Delete_File ("../" & Target);
      end if;
   end Test_Process_Dash_Filename_After_Terminator;

   procedure Test_Process_Program_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 6) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/begin.awk"),
         new String'("-ftests/fixtures/programs/print-first.awk"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("tests/fixtures/input/second.txt"),
         new String'("name=value")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process -f",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process -f exits successfully");
      Assert (Contains (U.To_String (Output), "begin" & LF & "one" & LF & "three"),
              "process -f loads files in order and reads first input");
      Assert (Contains (U.To_String (Output), "five" & LF),
              "process -f reads second input after runtime assignment operand");
   end Test_Process_Program_Files;

   procedure Test_Process_Help_Color_Never (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("--color=never"), new String'("--help")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk help no color",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process help exits successfully");
      Assert (Contains (U.To_String (Output), "Usage: awk"), "help includes usage");
      Assert (not Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=never suppresses ANSI escapes");
   end Test_Process_Help_Color_Never;

   procedure Test_Process_Help_Short_Circuits_Runtime
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 4) :=
        [new String'("--help"),
         new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk"),
         new String'("BEGIN {")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk help short circuit",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "help ignores later runtime failures");
      Assert (Contains (U.To_String (Output), "Usage: awk"), "help text is emitted");
   end Test_Process_Help_Short_Circuits_Runtime;

   procedure Test_Process_Help_Color_Always (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("--color=always"), new String'("--help")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk help color always",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process help color always exits successfully");
      Assert (Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=always styles CLI-owned help");
   end Test_Process_Help_Color_Always;

   procedure Test_Process_Help_Auto_Respects_No_Color
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Project_Tools.Processes.Locate_Command ("env");
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 4) :=
        [new String'("NO_COLOR=1"),
         new String'("./bin/awk"),
         new String'("--color=auto"),
         new String'("--help")];
      Status : Integer;
   begin
      Assert (Env /= "", "env executable is available for environment-bound process test");
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk help auto no color",
           Dir     => "..",
           Program => Env,
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "process help auto with NO_COLOR exits successfully");
      Assert (Contains (U.To_String (Output), "Usage: awk"), "help includes usage");
      Assert (not Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=auto honors NO_COLOR through terminal_styles");
   end Test_Process_Help_Auto_Respects_No_Color;

   procedure Test_Process_Version_Short_Circuits_Runtime
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("--version"),
         new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk version short circuit",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "version ignores later runtime failures");
      Assert (Contains (U.To_String (Output), "awk 0.1.0"), "version text is emitted");
   end Test_Process_Version_Short_Circuits_Runtime;

   procedure Test_Process_Awk_Output_Unstyled_With_Color_Always
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("--color=always"),
         new String'("BEGIN { print ""plain"" }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk output color always",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process AWK output color always exits successfully");
      Assert (Contains (U.To_String (Output), "plain" & LF), "AWK output is present");
      Assert (not Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=always does not style AWK output");
   end Test_Process_Awk_Output_Unstyled_With_Color_Always;

   procedure Test_Process_Usage_Status (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--bad-option")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk usage failure",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 2, "unknown option exits with usage status");
   end Test_Process_Usage_Status;

   procedure Test_Process_Missing_Program_File (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk missing program file",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 3, "missing process program file exits with host I/O status");
      Assert (U.To_String (Output) = "", "missing process program file writes no stdout");
   end Test_Process_Missing_Program_File;

   procedure Test_Process_Missing_Input_File (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print }"),
         new String'("tests/fixtures/input/no-such-input.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk missing input file",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 3, "missing process input file exits with host I/O status");
      Assert (U.To_String (Output) = "", "missing process input file writes no stdout");
   end Test_Process_Missing_Input_File;

   procedure Test_Process_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/process_redir.txt";
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print ""saved"" > """ & Target & """ }")];
      Status : Integer;
   begin
      if Ada.Directories.Exists ("../" & Target) then
         Ada.Directories.Delete_File ("../" & Target);
      end if;

      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process redirection",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);

      Assert (Status = 0, "process redirection exits successfully");
      Assert (U.To_String (Output) = "", "process redirected output not on stdout");
      Assert (File_Text ("../" & Target) = "saved", "process redirection file content");

      if Ada.Directories.Exists ("../" & Target) then
         Ada.Directories.Delete_File ("../" & Target);
      end if;
   end Test_Process_Redirection;

   procedure Test_Process_Append_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/process_append.txt";
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print ""first"" >> """ & Target & """; print ""second"" >> """ & Target & """ }")];
      Status : Integer;
   begin
      if Ada.Directories.Exists ("../" & Target) then
         Ada.Directories.Delete_File ("../" & Target);
      end if;
      Write_Text_File ("../" & Target, "existing" & LF);

      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process append redirection",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);

      Assert (Status = 0, "process append redirection exits successfully");
      Assert (U.To_String (Output) = "", "process append redirection not on stdout");
      Assert
        (Contains (File_Text ("../" & Target), "existing") and then
         Contains (File_Text ("../" & Target), "first" & LF & "second"),
         "append redirection preserves existing file content");

      if Ada.Directories.Exists ("../" & Target) then
         Ada.Directories.Delete_File ("../" & Target);
      end if;
   end Test_Process_Append_Redirection;

   procedure Test_Process_Field_Separator (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 4) :=
        [new String'("-F"),
         new String'(" "),
         new String'("{ print $1 ""/"" $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process -F",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process -F exits successfully");
      Assert (Contains (U.To_String (Output), "one/two" & LF & "three/four"),
              "process -F splits fields");
   end Test_Process_Field_Separator;

   procedure Test_Process_V_Assignment (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("-vX=41"),
         new String'("BEGIN { print X + 1 }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process -v",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process -v exits successfully");
      Assert (Contains (U.To_String (Output), "42" & LF), "process -v is visible before BEGIN");
   end Test_Process_V_Assignment;

   procedure Test_Process_Environment_Propagation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Project_Tools.Processes.Locate_Command ("env");
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 4) :=
        [new String'("AWK_PROCESS_ENV=visible"),
         new String'("./bin/awk"),
         new String'("BEGIN { print ENVIRON[""AWK_PROCESS_ENV""] }"),
         new String'("unused=value")];
      Status : Integer;
   begin
      Assert (Env /= "", "env executable is available for environment-bound process test");
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process environment",
           Dir     => "..",
           Program => Env,
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "process environment propagation exits successfully");
      Assert (Contains (U.To_String (Output), "visible" & LF),
              "process environment reaches awklib ENVIRON");
   end Test_Process_Environment_Propagation;

   procedure Test_Process_Explicit_Stdin_Eof
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print }"),
         new String'("-")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process explicit stdin eof",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "explicit stdin operand accepts EOF");
      Assert (U.To_String (Output) = "", "EOF stdin produces no records");
   end Test_Process_Explicit_Stdin_Eof;

   procedure Test_Process_Explicit_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print NR "":"" $2 }"),
         new String'("-")];
      Status : aliased Integer := -1;
      Output : constant String :=
        GNAT.Expect.Get_Command_Output
          (Command   => "../bin/awk",
           Arguments => Args,
           Input     => "one two" & LF & "three four" & LF,
           Status    => Status'Access);
   begin
      Assert (Status = 0, "explicit stdin data exits successfully");
      Assert (Output = "1:two" & LF & "2:four",
              "process stdin data reaches installed executable");
   end Test_Process_Explicit_Stdin_Data;

   procedure Test_Process_Runtime_Assignment_Argv
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("BEGIN { print ARGC; print ARGV[1]; print ARGV[2] }"),
         new String'("name=value"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process runtime assignment argv",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process runtime assignment ARGV exits successfully");
      Assert (Contains (U.To_String (Output), "3" & LF & "name=value" & LF),
              "runtime assignment spelling is preserved in ARGV");
      Assert (Contains (U.To_String (Output), "tests/fixtures/input/basic.txt"),
              "input filename remains ordered after runtime assignment");
   end Test_Process_Runtime_Assignment_Argv;

   procedure Test_Process_Parse_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN {")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process parse failure",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 1, "process parse failure exits with interpreter status");
      Assert (U.To_String (Output) = "", "parse failure does not write stdout");
   end Test_Process_Parse_Failure;

   procedure Test_Process_Multiple_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("{ print FILENAME "":"" FNR "":"" $1 }"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("tests/fixtures/input/second.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process multiple files",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process multiple files exits successfully");
      Assert (Contains (U.To_String (Output), "tests/fixtures/input/basic.txt:1:one"),
              "first file FILENAME/FNR visible");
      Assert (Contains (U.To_String (Output), "tests/fixtures/input/second.txt:1:five"),
              "second file FILENAME/FNR visible");
   end Test_Process_Multiple_Files;

   procedure Test_Process_Command_Getline (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { ""printf x"" | getline value; print value }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process command getline",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process command getline exits successfully");
      Assert (Contains (U.To_String (Output), "x"),
              "process command getline reads command output");
   end Test_Process_Command_Getline;

   overriding procedure Register_Tests (T : in out CLI_Case) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Context_Direct_Run'Access, "context direct run");
      Registration.Register_Routine (T, Test_Context_File_Run'Access, "context file run");
      Registration.Register_Routine (T, Test_Context_Output_Failure'Access, "context output failure");
      Registration.Register_Routine
        (T, Test_Context_Standard_Input_Failure'Access,
         "context standard input failure");
      Registration.Register_Routine
        (T, Test_Context_Named_File_Does_Not_Read_Stdin'Access,
         "context named file skips stdin");
      Registration.Register_Routine (T, Test_Context_Program_File_Failure'Access, "context program file failure");
      Registration.Register_Routine (T, Test_Context_Input_File_Failure'Access, "context input file failure");
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
      Registration.Register_Routine (T, Test_Context_Repeated_Stdin'Access, "context repeated stdin");
      Registration.Register_Routine
        (T, Test_Context_Assignment_Only_Uses_Implicit_Stdin'Access,
         "context assignment-only implicit stdin");
      Registration.Register_Routine
        (T, Test_Context_Mixed_Input_Order_And_Spelling'Access,
         "context mixed input order and spelling");
      Registration.Register_Routine (T, Test_Compatibility_Registry'Access, "compatibility registry");
      Registration.Register_Routine (T, Test_Conformance_Manifest'Access, "conformance manifest");
      Registration.Register_Routine (T, Test_Process_Version'Access, "process version");
      Registration.Register_Routine (T, Test_Process_Direct_File_Input'Access, "process direct file input");
      Registration.Register_Routine
        (T, Test_Process_Dash_Filename_After_Terminator'Access,
         "process dash filename after terminator");
      Registration.Register_Routine (T, Test_Process_Program_Files'Access, "process -f program files");
      Registration.Register_Routine (T, Test_Process_Help_Color_Never'Access, "process help color never");
      Registration.Register_Routine
        (T, Test_Process_Help_Short_Circuits_Runtime'Access,
         "process help short circuit");
      Registration.Register_Routine (T, Test_Process_Help_Color_Always'Access, "process help color always");
      Registration.Register_Routine
        (T, Test_Process_Help_Auto_Respects_No_Color'Access,
         "process help auto NO_COLOR");
      Registration.Register_Routine
        (T, Test_Process_Version_Short_Circuits_Runtime'Access,
         "process version short circuit");
      Registration.Register_Routine
        (T, Test_Process_Awk_Output_Unstyled_With_Color_Always'Access,
         "process AWK output color always");
      Registration.Register_Routine (T, Test_Process_Usage_Status'Access, "process usage status");
      Registration.Register_Routine
        (T, Test_Process_Missing_Program_File'Access,
         "process missing program file");
      Registration.Register_Routine
        (T, Test_Process_Missing_Input_File'Access,
         "process missing input file");
      Registration.Register_Routine (T, Test_Process_Redirection'Access, "process redirection");
      Registration.Register_Routine (T, Test_Process_Append_Redirection'Access, "process append redirection");
      Registration.Register_Routine (T, Test_Process_Field_Separator'Access, "process -F");
      Registration.Register_Routine (T, Test_Process_V_Assignment'Access, "process -v");
      Registration.Register_Routine
        (T, Test_Process_Environment_Propagation'Access,
         "process environment propagation");
      Registration.Register_Routine
        (T, Test_Process_Explicit_Stdin_Eof'Access,
         "process explicit stdin eof");
      Registration.Register_Routine
        (T, Test_Process_Explicit_Stdin_Data'Access,
         "process explicit stdin data");
      Registration.Register_Routine
        (T, Test_Process_Runtime_Assignment_Argv'Access,
         "process runtime assignment ARGV");
      Registration.Register_Routine (T, Test_Process_Parse_Failure'Access, "process parse failure");
      Registration.Register_Routine (T, Test_Process_Multiple_Files'Access, "process multiple files");
      Registration.Register_Routine (T, Test_Process_Command_Getline'Access, "process command getline");
   end Register_Tests;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite := new AUnit.Test_Suites.Test_Suite;
   begin
      pragma Warnings (Off, "use of an anonymous access type allocator");
      Result.Add_Test (new Awk_Tests.CLI_Options.Case_Type);
      Result.Add_Test (new Awk_Tests.Diagnostics.Case_Type);
      Result.Add_Test (new Awk_Tests.Execution.Case_Type);
      Result.Add_Test (new Awk_Tests.Localization.Case_Type);
      Result.Add_Test (new Awk_Tests.Operands.Case_Type);
      Result.Add_Test (new Awk_Tests.Program_Sources.Case_Type);
      Result.Add_Test (new Awk_Tests.Redirections.Case_Type);
      Result.Add_Test (new CLI_Case);
      pragma Warnings (On, "use of an anonymous access type allocator");
      return Result;
   end Suite;
end Awk_Tests.Suite;
