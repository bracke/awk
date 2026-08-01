package body Awk_CLI.Redirections is
   package D renames Awk_CLI.Diagnostics;

   function Materialize
     (Outputs    : Awk_CLI.Execution.Redirection_Vectors.Vector;
      Write_File : Write_File_Access) return Materialize_Result
   is
   begin
      for Item of Outputs loop
         declare
            Path : constant String := U.To_String (Item.Path);
         begin
            if not Write_File (Path, U.To_String (Item.Content), Item.Append) then
               return
                 (Ok => False,
                  Diagnostic =>
                    D.Make ("awk.output_file.write_failed", D.Error, D.Output,
                            Name => "path", Value => Path));
            end if;
         end;
      end loop;
      return (Ok => True);
   end Materialize;
end Awk_CLI.Redirections;
