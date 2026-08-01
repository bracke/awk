with Ada.Environment_Variables;

package body Awk_CLI.Environment is
   function Collect return Entry_Vectors.Vector is
      Result : Entry_Vectors.Vector;

      procedure Add (Name, Value : String) is
      begin
         Result.Append
           (Env_Entry'(Name => U.To_Unbounded_String (Name),
                       Value => U.To_Unbounded_String (Value)));
      end Add;
   begin
      Ada.Environment_Variables.Iterate (Add'Access);
      return Result;
   exception
      when others =>
         return Result;
   end Collect;
end Awk_CLI.Environment;
