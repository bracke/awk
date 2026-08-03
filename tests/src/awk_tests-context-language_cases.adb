with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Testing;

package body Awk_Tests.Context.Language_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;

   LF : constant String := [1 => ASCII.LF];
   use type Awk_CLI.Exit_Code;

   procedure Test_Context_Expressions_Regex_And_Builtins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument
        (Context,
         "BEGIN { print ENVIRON[""AWK_TEST_ENV""]; print length(""abcd"") } " &
         "/^[a-z]+ [0-9]+$/ { print $1, $2 + 3, substr($1, 2, 2) }");
      Harness.Add_Environment (Context, "AWK_TEST_ENV", "visible");
      Harness.Set_Standard_Input (Context, "abc 4" & LF & "NOPE" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "expression integration succeeds");
      Assert
        (Harness.Standard_Output (Context) =
         "visible" & LF & "4" & LF & "abc 7 bc" & LF,
         "ENVIRON, regex pattern, arithmetic, and builtins pass through awklib");

      Awk_CLI.Clear (Context);
      Harness.Add_Argument
        (Context, "BEGIN { s = ""aa""; sub(/a|aa/, ""X"", s); print s }");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "leftmost-longest regex integration succeeds");
      Assert (Harness.Standard_Output (Context) = "X" & LF,
              "regex replacement uses awklib leftmost-longest selection");
   end Test_Context_Expressions_Regex_And_Builtins;

   procedure Test_Context_Auxiliary_Getline_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument
        (Context, "BEGIN { getline line < ""aux.txt""; print line }");
      Harness.Add_Argument (Context, "aux.txt");
      Harness.Add_File (Context, "aux.txt", "from aux" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "auxiliary getline integration succeeds");
      Assert (Harness.Standard_Output (Context) = "from aux" & LF,
              "getline < file uses files registered through the execution adapter");
   end Test_Context_Auxiliary_Getline_File;

   procedure Test_Context_Main_Getline_From_Begin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument
        (Context,
         "BEGIN { getline line; print FILENAME, FNR, NR, line }"
         & " { print ""main"", FNR, NR, $0 }");
      Harness.Add_Argument (Context, "-");
      Harness.Set_Standard_Input (Context, "first" & LF & "second" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "main-input getline from BEGIN succeeds");
      Assert
        (Harness.Standard_Output (Context) =
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
      Harness.Add_Argument
        (Context,
         "BEGIN { ""printf x"" | getline value; print value }");
      Harness.Add_Command_Output (Context, "printf x", "x");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "command getline succeeds");
      Assert (Harness.Standard_Output (Context) = "x" & LF,
              "command getline uses awklib command callback output");
   end Test_Context_Command_Getline;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
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
   end Register;
end Awk_Tests.Context.Language_Cases;
