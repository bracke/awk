with Ada.Strings.Unbounded;

with Project_Tools.Text;

package body Awk_Tests.Support is
   package U renames Ada.Strings.Unbounded;

   function File_Text (Path : String) return String is
      Result : constant String :=
        U.To_String (Project_Tools.Text.Read_Text_File (Path));
   begin
      if Result'Length > 0 and then Result (Result'Last) = ASCII.LF then
         return Result (Result'First .. Result'Last - 1);
      else
         return Result;
      end if;
   end File_Text;

end Awk_Tests.Support;
