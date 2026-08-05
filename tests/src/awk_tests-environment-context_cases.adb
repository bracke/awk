with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Testing;
with Project_Tools.Text;

package body Awk_Tests.Environment.Context_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;

   LF : constant String := [1 => ASCII.LF];
   use type Awk_CLI.Exit_Code;

   procedure Test_Context_Environment (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "BEGIN { print ENVIRON[""AWK_TEST_ENV""] }");
      Harness.Add_Environment (Context, "AWK_TEST_ENV", "present");
      Status := Awk_CLI.Run (Context);

      Assert (Status = 0, "environment run succeeds");
      Assert
        (Harness.Standard_Output (Context) = "present" & LF,
         "environment entry reaches awklib");
   end Test_Context_Environment;

   procedure Test_Normalization_And_Confidentiality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument
        (Context, "BEGIN { print ENVIRON[""AWK_DUP""]; print ENVIRON[""""] }");
      Harness.Add_Environment (Context, "AWK_DUP", "old-secret");
      Harness.Add_Environment (Context, "", "empty-secret");
      Harness.Add_Environment (Context, "AWK_DUP", "new-secret");
      Status := Awk_CLI.Run (Context);

      Assert (Status = 0, "normalized environment run succeeds");
      Assert
        (Harness.Standard_Output (Context) = "new-secret" & LF & LF,
         "duplicate env uses final value and empty env name is ignored");

      Awk_CLI.Clear (Context);
      Harness.Add_Argument (Context, "{ print }");
      Harness.Add_Argument (Context, "missing.txt");
      Harness.Add_Environment (Context, "AWK_SECRET", "do-not-leak");
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);

      Assert (Status = 3, "missing input remains host I/O");
      Assert
        (not Project_Tools.Text.Contains
           (Harness.Standard_Error (Context), "do-not-leak"),
         "environment values are not emitted in unrelated diagnostics");
   end Test_Normalization_And_Confidentiality;
end Awk_Tests.Environment.Context_Cases;
