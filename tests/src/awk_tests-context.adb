with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Execution;

package body Awk_Tests.Context is
   use AUnit.Assertions;

   LF : constant String := [1 => ASCII.LF];
   use type Awk_CLI.Exit_Code;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk context");
   end Name;

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

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Context_Direct_Run'Access, "context direct run");
      Registration.Register_Routine (T, Test_Context_File_Run'Access, "context file run");
      Registration.Register_Routine (T, Test_Context_Output_Failure'Access, "context output failure");
      Registration.Register_Routine (T, Test_Context_Stderr_Failure'Access, "context stderr failure");
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
   end Register_Tests;
end Awk_Tests.Context;
