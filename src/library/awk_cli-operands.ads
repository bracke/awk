with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Awk_CLI.Options;

package Awk_CLI.Operands is
   package U renames Ada.Strings.Unbounded;

   type Operand_Kind is (Named_File, Standard_Input, Runtime_Assignment);

   type Classified_Operand is record
      Kind           : Operand_Kind := Named_File;
      Text           : U.Unbounded_String;
      Name           : U.Unbounded_String;
      Value          : U.Unbounded_String;
      Original_Index : Positive := 1;
   end record;

   package Operand_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Classified_Operand);

   function Classify
     (Operands : Awk_CLI.Options.Operand_Vectors.Vector) return Operand_Vectors.Vector;
end Awk_CLI.Operands;
