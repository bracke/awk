with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Awk_CLI.Diagnostics;
with Awk_CLI.Options;

package Awk_CLI.Programs is
   package U renames Ada.Strings.Unbounded;

   type Source_Segment is record
      Display_Name : U.Unbounded_String;
      Start_Line   : Positive := 1;
      End_Line     : Natural := 0;
   end record;

   package Segment_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Source_Segment);

   type Program_Source is record
      Text     : U.Unbounded_String;
      Segments : Segment_Vectors.Vector;
      Operands : Awk_CLI.Options.Operand_Vectors.Vector;
   end record;

   type Resolve_Result (Ok : Boolean := False) is record
      case Ok is
         when True =>
            Source : Program_Source;
         when False =>
            Diagnostic : Awk_CLI.Diagnostics.Diagnostic;
      end case;
   end record;

   function Resolve
     (Options   : Awk_CLI.Options.Parsed_Options;
      Read_File : not null access function
        (Path : String; Content : out U.Unbounded_String) return Boolean)
      return Resolve_Result;
end Awk_CLI.Programs;
