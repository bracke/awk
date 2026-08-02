with AUnit.Assertions;

with Ada.Environment_Variables;

with Awk_CLI;
with Awk_Tests.Support;

package body Awk_Tests.Terminal_Styles is
   use AUnit.Assertions;
   use Awk_Tests.Support;
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
      No_Color_Found : constant Boolean := Ada.Environment_Variables.Exists ("NO_COLOR");
      No_Color_Value : constant String :=
        (if No_Color_Found then Ada.Environment_Variables.Value ("NO_COLOR") else "");
      Esc : constant String := [1 => Character'Val (27)];
   begin
      Ada.Environment_Variables.Clear ("NO_COLOR");
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
              (Contains (Awk_CLI.Standard_Output (Context), Esc & "["),
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
              (not Contains (Awk_CLI.Standard_Error (Context), Esc & "["),
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
              (Contains (Awk_CLI.Standard_Error (Context), Esc & "["),
               "auto color styles terminal stderr diagnostic");
            Assert (Awk_CLI.Standard_Output (Context) = "", "diagnostic writes no stdout");
         end;
      exception
         when others =>
            if No_Color_Found then
               Ada.Environment_Variables.Set ("NO_COLOR", No_Color_Value);
            else
               Ada.Environment_Variables.Clear ("NO_COLOR");
            end if;
            raise;
      end;

      if No_Color_Found then
         Ada.Environment_Variables.Set ("NO_COLOR", No_Color_Value);
      else
         Ada.Environment_Variables.Clear ("NO_COLOR");
      end if;
   end Test_Context_Auto_Color_Destinations;

   procedure Test_Context_Explicit_Color_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      No_Color_Found : constant Boolean := Ada.Environment_Variables.Exists ("NO_COLOR");
      No_Color_Value : constant String :=
        (if No_Color_Found then Ada.Environment_Variables.Value ("NO_COLOR") else "");
      Esc : constant String := [1 => Character'Val (27)];
   begin
      Ada.Environment_Variables.Clear ("NO_COLOR");
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
              (Contains (Awk_CLI.Standard_Error (Context), Esc & "["),
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
              (not Contains (Awk_CLI.Standard_Error (Context), Esc & "["),
               "color=never leaves terminal stderr diagnostics plain");
            Assert (Awk_CLI.Standard_Output (Context) = "", "diagnostic writes no stdout");
         end;
      exception
         when others =>
            if No_Color_Found then
               Ada.Environment_Variables.Set ("NO_COLOR", No_Color_Value);
            else
               Ada.Environment_Variables.Clear ("NO_COLOR");
            end if;
            raise;
      end;

      if No_Color_Found then
         Ada.Environment_Variables.Set ("NO_COLOR", No_Color_Value);
      else
         Ada.Environment_Variables.Clear ("NO_COLOR");
      end if;
   end Test_Context_Explicit_Color_Diagnostics;

   procedure Test_Context_Explicit_Color_Help
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      No_Color_Found : constant Boolean := Ada.Environment_Variables.Exists ("NO_COLOR");
      No_Color_Value : constant String :=
        (if No_Color_Found then Ada.Environment_Variables.Value ("NO_COLOR") else "");
      Esc : constant String := [1 => Character'Val (27)];
   begin
      Ada.Environment_Variables.Clear ("NO_COLOR");
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
              (Contains (Awk_CLI.Standard_Output (Context), Esc & "["),
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
              (not Contains (Awk_CLI.Standard_Output (Context), Esc & "["),
               "color=never leaves terminal stdout help plain");
            Assert (Awk_CLI.Standard_Error (Context) = "", "help writes no stderr");
         end;
      exception
         when others =>
            if No_Color_Found then
               Ada.Environment_Variables.Set ("NO_COLOR", No_Color_Value);
            else
               Ada.Environment_Variables.Clear ("NO_COLOR");
            end if;
            raise;
      end;

      if No_Color_Found then
         Ada.Environment_Variables.Set ("NO_COLOR", No_Color_Value);
      else
         Ada.Environment_Variables.Clear ("NO_COLOR");
      end if;
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
