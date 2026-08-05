with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Options;

package body Awk_Tests.CLI_Options.Core_Cases.Matrix_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Ada.Containers.Count_Type;
   use type Opt.Color_Mode;

   procedure Test_Option_Matrix (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-F"));
      Args.Append (U.To_Unbounded_String (":"));
      Args.Append (U.To_Unbounded_String ("-F,"));
      Args.Append (U.To_Unbounded_String ("-vempty="));
      Args.Append (U.To_Unbounded_String ("-v"));
      Args.Append (U.To_Unbounded_String ("path=a=b"));
      Args.Append (U.To_Unbounded_String ("--color=always"));
      Args.Append (U.To_Unbounded_String ("--color=never"));
      Args.Append (U.To_Unbounded_String ("{ print }"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "option matrix parses");
         Assert (U.To_String (Result.Options.Field_Separator) = ",", "final -F wins");
         Assert (Result.Options.Initial_Assignments.Length = 2,
                 "both -v assignments retained");
         Assert (U.To_String (Result.Options.Initial_Assignments.Element (1).Name) = "empty",
                 "empty assignment name preserved");
         Assert (U.To_String (Result.Options.Initial_Assignments.Element (1).Value) = "",
                 "empty assignment value preserved");
         Assert (U.To_String (Result.Options.Initial_Assignments.Element (2).Value) = "a=b",
                 "multiple equals preserved in value");
         Assert (Result.Options.Color = Opt.Color_Never, "final color wins");
      end;
   end Test_Option_Matrix;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Option_Matrix'Access, "option matrix");
   end Register;
end Awk_Tests.CLI_Options.Core_Cases.Matrix_Cases;
