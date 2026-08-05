with AUnit.Assertions;

with Awk_CLI;
with Awk_CLI.Testing;
with Project_Tools.Text;

package body Awk_Tests.Terminal_Styles.Auto_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;
   use type Awk_CLI.Exit_Code;

   Esc : constant String := [1 => Character'Val (27)];

   procedure Test_Context_Auto_Color_Destinations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Harness.Add_Argument (Context, "--color=auto");
         Harness.Add_Argument (Context, "--help");
         Harness.Set_Standard_Output_Terminal (Context, True);
         Harness.Set_Standard_Error_Terminal (Context, False);
         Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 0, "auto-color help succeeds");
         Assert
           (Project_Tools.Text.Contains (Harness.Standard_Output (Context), Esc & "["),
            "auto color styles terminal stdout help");
         Assert (Harness.Standard_Error (Context) = "", "help writes no stderr");
      end;

      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Harness.Add_Argument (Context, "--bad-option");
         Harness.Set_Standard_Output_Terminal (Context, True);
         Harness.Set_Standard_Error_Terminal (Context, False);
         Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 2, "usage diagnostic exits with usage status");
         Assert
           (not Project_Tools.Text.Contains (Harness.Standard_Error (Context), Esc & "["),
            "auto color leaves non-terminal stderr diagnostic plain");
      end;

      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Harness.Add_Argument (Context, "--bad-option");
         Harness.Set_Standard_Output_Terminal (Context, False);
         Harness.Set_Standard_Error_Terminal (Context, True);
         Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 2, "terminal stderr diagnostic exits with usage status");
         Assert
           (Project_Tools.Text.Contains (Harness.Standard_Error (Context), Esc & "["),
            "auto color styles terminal stderr diagnostic");
         Assert (Harness.Standard_Output (Context) = "", "diagnostic writes no stdout");
      end;

      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Harness.Add_Argument (Context, "--color=auto");
         Harness.Add_Argument (Context, "--help");
         Harness.Set_Standard_Output_Terminal (Context, True);
         Harness.Set_No_Color (Context, True);
         Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 0, "auto-color help with no-color succeeds");
         Assert
           (not Project_Tools.Text.Contains (Harness.Standard_Output (Context), Esc & "["),
            "auto color honors context no-color policy");
      end;
   end Test_Context_Auto_Color_Destinations;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Context_Auto_Color_Destinations'Access,
         "context auto color destinations");
   end Register;
end Awk_Tests.Terminal_Styles.Auto_Cases;
