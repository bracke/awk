with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Awk_CLI.Environment is
   --  Process environment collection and normalization for ENVIRON setup.

   package U renames Ada.Strings.Unbounded;

   type Env_Entry is record
      Name  : U.Unbounded_String;
      Value : U.Unbounded_String;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Env_Entry);

   function Collect return Entry_Vectors.Vector;
   --  Return environment entries visible through the Ada runtime.

   function Normalize (Entries : Entry_Vectors.Vector) return Entry_Vectors.Vector;
   --  Drop empty names and collapse duplicates while preserving first position
   --  and final value.
end Awk_CLI.Environment;
