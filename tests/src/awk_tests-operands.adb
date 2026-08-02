with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Operands;
with Awk_CLI.Options;

package body Awk_Tests.Operands is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Ada.Containers.Count_Type;
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

   procedure Test_Assignment_Syntax_Examples
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Raw : Opt.Operand_Vectors.Vector;
   begin
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("X=value"), Original_Index => 10));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("name="), Original_Index => 11));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("_private=42"), Original_Index => 12));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("value=a=b=c"), Original_Index => 13));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("123=value"), Original_Index => 14));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("dir/name=value"), Original_Index => 15));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("./X=value"), Original_Index => 16));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("a-b=value"), Original_Index => 17));

      declare
         Items : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Raw);
      begin
         Assert (Items.Length = 8, "all operands are retained");

         Assert (Items.Element (1).Kind = Awk_CLI.Operands.Runtime_Assignment,
                 "letter-start assignment recognized");
         Assert (U.To_String (Items.Element (1).Name) = "X", "assignment name before first equals");
         Assert (U.To_String (Items.Element (1).Value) = "value", "assignment value after first equals");

         Assert (Items.Element (2).Kind = Awk_CLI.Operands.Runtime_Assignment,
                 "empty assignment value recognized");
         Assert (U.To_String (Items.Element (2).Value) = "", "empty assignment value preserved");

         Assert (Items.Element (3).Kind = Awk_CLI.Operands.Runtime_Assignment,
                 "underscore-start assignment recognized");
         Assert (U.To_String (Items.Element (3).Name) = "_private", "underscore name preserved");

         Assert (Items.Element (4).Kind = Awk_CLI.Operands.Runtime_Assignment,
                 "multiple equals assignment recognized");
         Assert (U.To_String (Items.Element (4).Value) = "a=b=c",
                 "complete text after first equals is preserved");

         Assert (Items.Element (5).Kind = Awk_CLI.Operands.Named_File,
                 "digit-start text with equals is a filename");
         Assert (Items.Element (6).Kind = Awk_CLI.Operands.Named_File,
                 "slash text with equals is a filename");
         Assert (Items.Element (7).Kind = Awk_CLI.Operands.Named_File,
                 "relative path with equals is a filename");
         Assert (Items.Element (8).Kind = Awk_CLI.Operands.Named_File,
                 "dash in name with equals is a filename");

         Assert (Items.Element (8).Original_Index = 17,
                 "original operand index is preserved through classification");
      end;
   end Test_Assignment_Syntax_Examples;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Operands'Access, "operand classifier");
      Registration.Register_Routine
        (T, Test_Assignment_Syntax_Examples'Access,
         "operand assignment syntax examples");
   end Register_Tests;
end Awk_Tests.Operands;
