with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Testing;
with Project_Tools.Text;

package body Awk_Tests.Terminal_Styles.Explicit_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;
   use type Awk_CLI.Exit_Code;

   Esc : constant String := [1 => Character'Val (27)];

   procedure Test_Context_Explicit_Color_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Harness.Add_Argument (Context, "--color=always");
         Harness.Add_Argument (Context, "--bad-option");
         Harness.Set_Standard_Error_Terminal (Context, False);
         Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 2, "color=always diagnostic exits with usage status");
         Assert
           (Project_Tools.Text.Contains (Harness.Standard_Error (Context), Esc & "["),
            "color=always styles diagnostics even for non-terminal stderr");
         Assert (Harness.Standard_Output (Context) = "", "diagnostic writes no stdout");
      end;

      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Harness.Add_Argument (Context, "--color=never");
         Harness.Add_Argument (Context, "--bad-option");
         Harness.Set_Standard_Error_Terminal (Context, True);
         Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 2, "color=never diagnostic exits with usage status");
         Assert
           (not Project_Tools.Text.Contains (Harness.Standard_Error (Context), Esc & "["),
            "color=never leaves terminal stderr diagnostics plain");
         Assert (Harness.Standard_Output (Context) = "", "diagnostic writes no stdout");
      end;
   end Test_Context_Explicit_Color_Diagnostics;

   procedure Test_Context_Explicit_Color_Help
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Harness.Add_Argument (Context, "--color=always");
         Harness.Add_Argument (Context, "--help");
         Harness.Set_Standard_Output_Terminal (Context, False);
         Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 0, "color=always help exits successfully");
         Assert
           (Project_Tools.Text.Contains (Harness.Standard_Output (Context), Esc & "["),
            "color=always styles help for non-terminal stdout");
         Assert (Harness.Standard_Error (Context) = "", "help writes no stderr");
      end;

      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Harness.Add_Argument (Context, "--color=never");
         Harness.Add_Argument (Context, "--help");
         Harness.Set_Standard_Output_Terminal (Context, True);
         Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 0, "color=never help exits successfully");
         Assert
           (not Project_Tools.Text.Contains (Harness.Standard_Output (Context), Esc & "["),
            "color=never leaves terminal stdout help plain");
         Assert (Harness.Standard_Error (Context) = "", "help writes no stderr");
      end;
   end Test_Context_Explicit_Color_Help;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Context_Explicit_Color_Diagnostics'Access,
         "context explicit color diagnostics");
      Registration.Register_Routine
        (T, Test_Context_Explicit_Color_Help'Access,
         "context explicit color help");
   end Register;
end Awk_Tests.Terminal_Styles.Explicit_Cases;
