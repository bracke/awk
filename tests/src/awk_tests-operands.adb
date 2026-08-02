with AUnit.Assertions;

with Ada.Strings.Unbounded;

with Awk_CLI.Operands;
with Awk_CLI.Options;

package body Awk_Tests.Operands is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Awk_CLI.Operands.Operand_Kind;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk operands");
   end Name;

   procedure Test_Operands (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Raw : Opt.Operand_Vectors.Vector;
   begin
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("input"), Original_Index => 1));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("-"), Original_Index => 2));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("name=a=b"), Original_Index => 3));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("./X=value"), Original_Index => 4));
      declare
         Items : constant Awk_CLI.Operands.Operand_Vectors.Vector := Awk_CLI.Operands.Classify (Raw);
      begin
         Assert (Items.Element (1).Kind = Awk_CLI.Operands.Named_File, "file");
         Assert (Items.Element (2).Kind = Awk_CLI.Operands.Standard_Input, "stdin");
         Assert (Items.Element (3).Kind = Awk_CLI.Operands.Runtime_Assignment, "assignment");
         Assert (Items.Element (4).Kind = Awk_CLI.Operands.Named_File, "path with equals is file");
      end;
   end Test_Operands;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Operands'Access, "operand classifier");
   end Register_Tests;
end Awk_Tests.Operands;
