with AUnit.Assertions;

with Ada.Strings.Unbounded;

with Awk_CLI.Diagnostics;
with Awk_CLI.Options;

package body Awk_Tests.CLI_Options.Core_Cases.Failure_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Awk_CLI.Diagnostics.Exit_Code;

   procedure Test_Bad_Options (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("--color=sometimes"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (not Result.Ok, "bad color rejected");
         Assert
           (Awk_CLI.Diagnostics.Status_For (Result.Diagnostic) =
            Awk_CLI.Diagnostics.Usage_Exit,
            "bad color is usage");
      end;
   end Test_Bad_Options;

   procedure Test_Empty_Arguments_Report_Missing_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (not Result.Ok, "empty argument vector is a usage failure");
         Assert
           (Awk_CLI.Diagnostics.Status_For (Result.Diagnostic) =
            Awk_CLI.Diagnostics.Usage_Exit,
            "empty argument vector exits with usage status");
      end;
   end Test_Empty_Arguments_Report_Missing_Program;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Bad_Options'Access, "usage diagnostics");
      Registration.Register_Routine
        (T, Test_Empty_Arguments_Report_Missing_Program'Access,
         "empty arguments report missing program");
   end Register;
end Awk_Tests.CLI_Options.Core_Cases.Failure_Cases;
