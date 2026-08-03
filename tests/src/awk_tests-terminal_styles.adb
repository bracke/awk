with AUnit.Assertions;

with Awk_CLI;
with Project_Tools.Text;

package body Awk_Tests.Terminal_Styles is
   use AUnit.Assertions;
   use type Awk_CLI.Exit_Code;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk terminal styles");
   end Name;

   procedure Test_Context_Auto_Color_Destinations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Esc : constant String := [1 => Character'Val (27)];
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
           (Project_Tools.Text.Contains (Awk_CLI.Standard_Output (Context), Esc & "["),
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
           (not Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), Esc & "["),
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
           (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), Esc & "["),
            "auto color styles terminal stderr diagnostic");
         Assert (Awk_CLI.Standard_Output (Context) = "", "diagnostic writes no stdout");
      end;

      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Awk_CLI.Add_Argument (Context, "--color=auto");
         Awk_CLI.Add_Argument (Context, "--help");
         Awk_CLI.Set_Standard_Output_Terminal (Context, True);
         Awk_CLI.Set_No_Color (Context, True);
         Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 0, "auto-color help with no-color succeeds");
         Assert
           (not Project_Tools.Text.Contains (Awk_CLI.Standard_Output (Context), Esc & "["),
            "auto color honors context no-color policy");
      end;
   end Test_Context_Auto_Color_Destinations;

   procedure Test_Context_Explicit_Color_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Esc : constant String := [1 => Character'Val (27)];
   begin
      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Awk_CLI.Add_Argument (Context, "--color=always");
         Awk_CLI.Add_Argument (Context, "--bad-option");
         Awk_CLI.Set_Standard_Error_Terminal (Context, False);
         Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 2, "color=always diagnostic exits with usage status");
         Assert
           (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), Esc & "["),
            "color=always styles diagnostics even for non-terminal stderr");
         Assert (Awk_CLI.Standard_Output (Context) = "", "diagnostic writes no stdout");
      end;

      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Awk_CLI.Add_Argument (Context, "--color=never");
         Awk_CLI.Add_Argument (Context, "--bad-option");
         Awk_CLI.Set_Standard_Error_Terminal (Context, True);
         Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 2, "color=never diagnostic exits with usage status");
         Assert
           (not Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), Esc & "["),
            "color=never leaves terminal stderr diagnostics plain");
         Assert (Awk_CLI.Standard_Output (Context) = "", "diagnostic writes no stdout");
      end;
   end Test_Context_Explicit_Color_Diagnostics;

   procedure Test_Context_Explicit_Color_Help
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Esc : constant String := [1 => Character'Val (27)];
   begin
      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Awk_CLI.Add_Argument (Context, "--color=always");
         Awk_CLI.Add_Argument (Context, "--help");
         Awk_CLI.Set_Standard_Output_Terminal (Context, False);
         Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 0, "color=always help exits successfully");
         Assert
           (Project_Tools.Text.Contains (Awk_CLI.Standard_Output (Context), Esc & "["),
            "color=always styles help for non-terminal stdout");
         Assert (Awk_CLI.Standard_Error (Context) = "", "help writes no stderr");
      end;

      declare
         Context : Awk_CLI.Invocation_Context;
         Status  : Awk_CLI.Exit_Code;
      begin
         Awk_CLI.Add_Argument (Context, "--color=never");
         Awk_CLI.Add_Argument (Context, "--help");
         Awk_CLI.Set_Standard_Output_Terminal (Context, True);
         Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
         Status := Awk_CLI.Run (Context);
         Assert (Status = 0, "color=never help exits successfully");
         Assert
           (not Project_Tools.Text.Contains (Awk_CLI.Standard_Output (Context), Esc & "["),
            "color=never leaves terminal stdout help plain");
         Assert (Awk_CLI.Standard_Error (Context) = "", "help writes no stderr");
      end;
   end Test_Context_Explicit_Color_Help;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Context_Auto_Color_Destinations'Access,
         "context auto color destinations");
      Registration.Register_Routine
        (T, Test_Context_Explicit_Color_Diagnostics'Access,
         "context explicit color diagnostics");
      Registration.Register_Routine
        (T, Test_Context_Explicit_Color_Help'Access,
         "context explicit color help");
   end Register_Tests;
end Awk_Tests.Terminal_Styles;
