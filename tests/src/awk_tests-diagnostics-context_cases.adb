with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Testing;
with Project_Tools.Text;

package body Awk_Tests.Diagnostics.Context_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;

   LF : constant String := [1 => ASCII.LF];
   use type Awk_CLI.Exit_Code;

   procedure Test_Context_Diagnostics (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "--bad");
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);

      Assert (Status = 2, "usage error status");
      Assert (Harness.Standard_Output (Context) = "", "usage error does not write stdout");
      Assert (Harness.Standard_Error (Context)'Length > 0, "diagnostic is captured");
      Assert (Harness.Has_Diagnostic (Context), "structured diagnostic is captured");
      Assert
        (Harness.Last_Diagnostic_Message_Id (Context) = "awk.usage.unknown_option",
         "structured diagnostic message ID is retained");
      Assert
        (Harness.Last_Diagnostic_Category (Context) = "USAGE",
         "structured diagnostic category is retained");
      Assert
        (Harness.Last_Diagnostic_Severity (Context) = "ERROR",
         "structured diagnostic severity is retained");
   end Test_Context_Diagnostics;

   procedure Test_Context_Diagnostic_Sanitizing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
      Escape  : constant String := [1 => Character'Val (27)];
   begin
      Harness.Add_Argument
        (Context, "--bad" & LF & "awk: error: forged" & Escape & "[2J");
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Status := Awk_CLI.Run (Context);

      Assert (Status = 2, "hostile option remains a usage error");
      Assert
        (not Project_Tools.Text.Contains
           (Harness.Standard_Error (Context), LF & "awk: error: forged"),
         "embedded newline cannot forge a diagnostic line");
      Assert
        (not Project_Tools.Text.Contains (Harness.Standard_Error (Context), Escape),
         "escape character is not emitted in diagnostics");
      Assert
        (Project_Tools.Text.Contains
           (Harness.Standard_Error (Context), "\nawk: error: forged\e[2J"),
         "unsafe characters are rendered visibly");
   end Test_Context_Diagnostic_Sanitizing;
end Awk_Tests.Diagnostics.Context_Cases;
