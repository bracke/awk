with Ada.Strings.Unbounded;
with Awk_CLI.Diagnostics;
with Awk_CLI.Execution;

package Awk_CLI.Redirections is
   package U renames Ada.Strings.Unbounded;

   type Write_Status is (Write_Success, Open_Failed, Write_Failed);

   type Materialize_Result (Ok : Boolean := True) is record
      case Ok is
         when True =>
            null;
         when False =>
            Diagnostic : Awk_CLI.Diagnostics.Diagnostic;
      end case;
   end record;

   function Materialize
     (Outputs    : Awk_CLI.Execution.Redirection_Vectors.Vector;
      Write_File : not null access function
        (Path : String; Content : String; Append : Boolean) return Write_Status)
      return Materialize_Result;
end Awk_CLI.Redirections;
