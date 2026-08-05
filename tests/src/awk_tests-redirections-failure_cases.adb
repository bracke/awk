with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Testing;
with Project_Tools.Text;

package body Awk_Tests.Redirections.Failure_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;

   LF : constant String := [1 => ASCII.LF];

   use type Awk_CLI.Exit_Code;

   procedure Test_Context_Redirection_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "BEGIN { print ""x"" > ""out.txt"" }");
      Harness.Add_File (Context, "out.txt", "", Readable => True, Writable => False);
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "redirection write failure is host I/O");
      Assert (Project_Tools.Text.Contains (Harness.Standard_Error (Context), "cannot write output file"),
              "redirection diagnostic is rendered");
   end Test_Context_Redirection_Failure;

   procedure Test_Context_Redirection_Fails_After_Partial_Materialization
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument
        (Context,
         "BEGIN { print ""ok"" > ""first.txt""; print ""blocked"" > ""second.txt""; print ""stdout"" }");
      Harness.Add_File (Context, "second.txt", "", Readable => True, Writable => False);
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "later redirection write failure is fatal");
      Assert (Harness.Written_File_Count (Context) = 1,
              "successful prior redirection write is recorded");
      Assert (Harness.Written_File_Name (Context, 1) = "first.txt",
              "prior redirection target is retained");
      Assert (Harness.Written_File_Content (Context, 1) = "ok" & LF,
              "prior redirection content is exact");
      Assert (Harness.Standard_Output (Context) = "",
              "stdout is not emitted after required redirection failure");
      Assert
        (Harness.Last_Diagnostic_Message_Id (Context) = "awk.output_file.write_failed",
         "structured diagnostic identifies later redirection write failure");
   end Test_Context_Redirection_Fails_After_Partial_Materialization;

   procedure Test_Context_Redirection_Open_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "BEGIN { print ""x"" > ""out.txt"" }");
      Harness.Add_File
        (Context, "out.txt", "", Readable => True, Writable => True, Openable => False);
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 3, "redirection open failure is host I/O");
      Assert (Project_Tools.Text.Contains (Harness.Standard_Error (Context), "cannot open output file"),
              "redirection open diagnostic is rendered");
      Assert
        (Harness.Last_Diagnostic_Message_Id (Context) = "awk.output_file.open_failed",
         "structured diagnostic identifies output open failure");
   end Test_Context_Redirection_Open_Failure;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Context_Redirection_Failure'Access,
         "context redirection failure");
      Registration.Register_Routine
        (T, Test_Context_Redirection_Fails_After_Partial_Materialization'Access,
         "context redirection partial failure");
      Registration.Register_Routine
        (T, Test_Context_Redirection_Open_Failure'Access,
         "context redirection open failure");
   end Register;

end Awk_Tests.Redirections.Failure_Cases;
