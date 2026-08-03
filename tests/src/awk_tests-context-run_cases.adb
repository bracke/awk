with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Testing;

package body Awk_Tests.Context.Run_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;

   LF : constant String := [1 => ASCII.LF];
   use type Awk_CLI.Exit_Code;

   procedure Test_Context_Direct_Run (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "{ print $2 }");
      Harness.Set_Standard_Input (Context, "one two" & LF & "three four" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "direct run succeeds");
      Assert (Harness.Standard_Output (Context) = "two" & LF & "four" & LF,
              "stdout is captured exactly");
      Assert (Harness.Standard_Error (Context) = "", "no diagnostics");
      Assert (not Harness.Has_Diagnostic (Context), "success has no structured diagnostic");
   end Test_Context_Direct_Run;

   procedure Test_Context_File_Run (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "-f");
      Harness.Add_Argument (Context, "prog.awk");
      Harness.Add_Argument (Context, "input.txt");
      Harness.Add_File (Context, "prog.awk", "{ print FILENAME, FNR, $1 }");
      Harness.Add_File (Context, "input.txt", "alpha beta" & LF);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "file-backed run succeeds");
      Assert (Harness.Standard_Output (Context) = "input.txt 1 alpha" & LF,
              "virtual file input reaches awklib");
   end Test_Context_File_Run;

   procedure Test_Context_Output_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "BEGIN { print ""x"" }");
      Harness.Fail_Standard_Output (Context, True);
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "stdout failure is host I/O");
      Assert (Harness.Standard_Output (Context) = "",
              "failed stdout is not reported as written output");
      Assert (Harness.Has_Diagnostic (Context), "stdout failure records a structured diagnostic");
      Assert
        (Harness.Last_Diagnostic_Message_Id (Context) = "awk.standard_output.write_failed",
         "structured diagnostic identifies stdout write failure");
      Assert (Harness.Last_Diagnostic_Category (Context) = "OUTPUT",
              "stdout write failure diagnostic is output-category");
   end Test_Context_Output_Failure;

   procedure Test_Context_Stderr_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "--bad");
      Harness.Fail_Standard_Error (Context, True);
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "diagnostic stderr failure is host I/O");
      Assert (Harness.Standard_Error (Context) = "", "failed stderr is not reported as written");
      Assert (Harness.Has_Diagnostic (Context), "stderr failure preserves original diagnostic");
      Assert
        (Harness.Last_Diagnostic_Message_Id (Context) = "awk.usage.unknown_option",
         "stderr write failure does not replace the original diagnostic ID");
   end Test_Context_Stderr_Failure;

   procedure Test_Context_Help_Short_Circuits_Runtime_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "--help");
      Harness.Add_Argument (Context, "-f");
      Harness.Add_Argument (Context, "missing.awk");
      Harness.Add_Argument (Context, "missing-input.txt");
      Harness.Fail_Standard_Input (Context, True);
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "help ignores runtime state and exits successfully");
      Assert (Harness.Standard_Error (Context) = "", "help emits no diagnostic");
      Assert (not Harness.Has_Diagnostic (Context), "help records no diagnostic");
      Assert (Harness.Standard_Output (Context)'Length > 0, "help text is emitted");
   end Test_Context_Help_Short_Circuits_Runtime_State;

   procedure Test_Context_Version_Short_Circuits_Runtime_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "--version");
      Harness.Add_Argument (Context, "-f");
      Harness.Add_Argument (Context, "missing.awk");
      Harness.Add_Argument (Context, "missing-input.txt");
      Harness.Fail_Standard_Input (Context, True);
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "version ignores runtime state and exits successfully");
      Assert (Harness.Standard_Error (Context) = "", "version emits no diagnostic");
      Assert (not Harness.Has_Diagnostic (Context), "version records no diagnostic");
      Assert (Harness.Standard_Output (Context) = "awk 0.1.0" & LF &
                                           "awklib 0.1.0" & LF &
                                           "license MIT" & LF,
              "version text is emitted exactly");
   end Test_Context_Version_Short_Circuits_Runtime_State;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Context_Direct_Run'Access, "context direct run");
      Registration.Register_Routine (T, Test_Context_File_Run'Access, "context file run");
      Registration.Register_Routine
        (T, Test_Context_Output_Failure'Access, "context output failure");
      Registration.Register_Routine
        (T, Test_Context_Stderr_Failure'Access, "context stderr failure");
      Registration.Register_Routine
        (T, Test_Context_Help_Short_Circuits_Runtime_State'Access,
         "context help short circuit");
      Registration.Register_Routine
        (T, Test_Context_Version_Short_Circuits_Runtime_State'Access,
         "context version short circuit");
   end Register;
end Awk_Tests.Context.Run_Cases;
