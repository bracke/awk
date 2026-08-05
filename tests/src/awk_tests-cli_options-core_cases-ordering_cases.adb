with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Options;

package body Awk_Tests.CLI_Options.Core_Cases.Ordering_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Ada.Containers.Count_Type;

   procedure Test_Option_Order_And_Index_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-vA=1"));
      Args.Append (U.To_Unbounded_String ("-f"));
      Args.Append (U.To_Unbounded_String ("a.awk"));
      Args.Append (U.To_Unbounded_String ("-v"));
      Args.Append (U.To_Unbounded_String ("B=2"));
      Args.Append (U.To_Unbounded_String ("--"));
      Args.Append (U.To_Unbounded_String ("-dash"));
      Args.Append (U.To_Unbounded_String ("C=3"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "indexed option parse succeeds");
         Assert (Result.Options.Initial_Assignments.Length = 2,
                 "initial assignments retained");
         Assert (Result.Options.Initial_Assignments.Element (1).Original_Index = 1,
                 "attached -v original index retained");
         Assert (Result.Options.Program_Files.Element (1).Original_Index = 3,
                 "program file original index retained");
         Assert (Result.Options.Initial_Assignments.Element (2).Original_Index = 5,
                 "separate -v value original index retained");
         Assert (Result.Options.Operands.Element (1).Original_Index = 7,
                 "operand after -- original index retained");
         Assert (U.To_String (Result.Options.Operands.Element (1).Text) = "-dash",
                 "dash-leading operand after -- is preserved");
         Assert (Result.Options.Operands.Element (2).Original_Index = 8,
                 "assignment operand original index retained");
      end;
   end Test_Option_Order_And_Index_Preservation;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Option_Order_And_Index_Preservation'Access,
         "option order and indexes");
   end Register;
end Awk_Tests.CLI_Options.Core_Cases.Ordering_Cases;
