with Ada.Strings.Unbounded;
with Awk_CLI.Options;

package Awk_CLI.Platform is
   package U renames Ada.Strings.Unbounded;

   function Process_Arguments return Awk_CLI.Options.String_Vectors.Vector;
   function Read_Standard_Input return U.Unbounded_String;
   function Read_File (Path : String; Content : out U.Unbounded_String) return Boolean;
   function Write_File (Path : String; Content : String; Append : Boolean) return Boolean;
   function Write_Standard_Output (Content : String) return Boolean;
   function Write_Standard_Error (Content : String) return Boolean;
   function Locale return String;
   function Catalog_Path return String;
end Awk_CLI.Platform;
