with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Options;

package body Awk_Tests.CLI_Options.Core_Cases.Basic_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Ada.Containers.Count_Type;

   procedure Test_Options (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-F,"));
      Args.Append (U.To_Unbounded_String ("-v"));
      Args.Append (U.To_Unbounded_String ("name=a=b"));
      Args.Append (U.To_Unbounded_String ("{ print $1 }"));
      Args.Append (U.To_Unbounded_String ("--"));
      Args.Append (U.To_Unbounded_String ("-file"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "parse succeeds");
         Assert (Result.Options.Has_Field_Separator, "FS present");
         Assert (U.To_String (Result.Options.Field_Separator) = ",", "attached -F");
         Assert (Result.Options.Initial_Assignments.Length = 1, "-v retained");
         Assert (Result.Options.Operands.Length = 3, "operands retained after direct program");
         Assert (U.To_String (Result.Options.Operands.Element (2).Text) = "--",
                 "-- after direct program is an operand");
      end;
   end Test_Options;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Options'Access, "option parser");
   end Register;
end Awk_Tests.CLI_Options.Core_Cases.Basic_Cases;
