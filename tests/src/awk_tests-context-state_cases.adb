with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Execution;
with Awk_CLI.Testing;

package body Awk_Tests.Context.State_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;

   LF : constant String := [1 => ASCII.LF];
   use type Awk_CLI.Exit_Code;

   procedure Test_Context_Clear_Resets_Runtime_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "--bad");
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 2, "first run records a usage diagnostic");
      Assert (Harness.Has_Diagnostic (Context), "first run has structured diagnostic");
      Assert (Harness.Standard_Error (Context)'Length > 0, "first run writes stderr");

      Awk_CLI.Clear (Context);
      Assert (Harness.Standard_Output (Context) = "", "clear resets stdout buffer");
      Assert (Harness.Standard_Error (Context) = "", "clear resets stderr buffer");
      Assert (not Harness.Has_Diagnostic (Context), "clear resets diagnostic state");
      Assert (Harness.Written_File_Count (Context) = 0, "clear resets redirected writes");

      Harness.Add_Argument (Context, "BEGIN { print ENVIRON[""LEAK""] }");
      Harness.Add_Environment (Context, "LEAK", "second");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "second run succeeds after clear");
      Assert (Harness.Standard_Output (Context) = "second" & LF,
              "second run uses only post-clear runtime state");
      Assert (Harness.Standard_Error (Context) = "", "second run has no old stderr");

      Awk_CLI.Clear (Context);
      Harness.Add_Argument (Context, "BEGIN { print ""x"" }");
      Harness.Fail_Standard_Output (Context, True);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "stdout failure can be enabled after clear");

      Awk_CLI.Clear (Context);
      Harness.Add_Argument (Context, "BEGIN { print ""ok"" }");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "clear resets stdout failure flag");
      Assert (Harness.Standard_Output (Context) = "ok" & LF,
              "stdout works after clear resets failure flag");
   end Test_Context_Clear_Resets_Runtime_State;

   procedure Test_Context_Argv_Argc (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument
        (Context,
         "BEGIN { print ARGC; print ARGV[0]; print ARGV[1]; print ARGV[2]; print ARGV[3] }");
      Harness.Add_Argument (Context, "input.txt");
      Harness.Add_Argument (Context, "name=value");
      Harness.Add_Argument (Context, "-");
      Harness.Add_File (Context, "input.txt", "ignored" & LF);
      Harness.Set_Standard_Input (Context, "stdin" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "ARGV/ARGC run succeeds");
      Assert
        (Harness.Standard_Output (Context) =
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
      Harness.Add_Argument
        (Context,
         "BEGIN { print ""begin"", X } " &
         "{ print FILENAME, FNR, X, $0 } " &
         "END { print ""end"", X }");
      Harness.Add_Argument (Context, "first.txt");
      Harness.Add_Argument (Context, "X=42");
      Harness.Add_Argument (Context, "first.txt");
      Harness.Add_Argument (Context, "X=99");
      Harness.Add_File (Context, "first.txt", "one" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "runtime assignment run succeeds");
      Assert (Awk_CLI.Execution.Supports_Positional_Runtime_Assignments,
              "execution adapter exposes positional assignment support");
      Assert
        (Harness.Standard_Output (Context) =
         "begin " & LF &
         "first.txt 1  one" & LF &
         "first.txt 1 42 one" & LF &
         "end 99" & LF,
         "runtime assignments are applied at operand positions");
   end Test_Context_Runtime_Assignment_Positions;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Context_Clear_Resets_Runtime_State'Access,
         "context clear resets runtime state");
      Registration.Register_Routine (T, Test_Context_Argv_Argc'Access, "context ARGV/ARGC");
      Registration.Register_Routine
        (T, Test_Context_Runtime_Assignment_Positions'Access,
         "context runtime assignment positions");
   end Register;
end Awk_Tests.Context.State_Cases;
