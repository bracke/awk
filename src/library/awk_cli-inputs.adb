package body Awk_CLI.Inputs is
   package D renames Awk_CLI.Diagnostics;

   function Load
     (Operands  : Awk_CLI.Operands.Operand_Vectors.Vector;
      Stdin     : String;
      Read_File : not null access function
        (Path : String; Content : out U.Unbounded_String) return Boolean)
      return Load_Result
   is
      Result       : Input_File_Vectors.Vector;
      Had_Input    : Boolean := False;
      Stdin_Unused : Boolean := True;
   begin
      for Item of Operands loop
         case Item.Kind is
            when Awk_CLI.Operands.Named_File =>
               Had_Input := True;
               declare
                  Path    : constant String := U.To_String (Item.Text);
                  Content : U.Unbounded_String;
               begin
                  if not Read_File (Path, Content) then
                     return
                       (Ok => False,
                        Diagnostic =>
                          D.Make ("awk.input_file.read_failed", D.Error, D.Input,
                                  Name => "path", Value => Path));
                  end if;
                  Result.Append (Input_File'(Name => Item.Text, Content => Content));
               end;
            when Awk_CLI.Operands.Standard_Input =>
               Had_Input := True;
               if Stdin_Unused then
                  Result.Append
                    (Input_File'(Name => U.To_Unbounded_String ("-"),
                                 Content => U.To_Unbounded_String (Stdin)));
                  Stdin_Unused := False;
               else
                  Result.Append
                    (Input_File'(Name => U.To_Unbounded_String ("-"),
                                 Content => U.Null_Unbounded_String));
               end if;
            when Awk_CLI.Operands.Runtime_Assignment =>
               null;
         end case;
      end loop;

      if not Had_Input then
         Result.Append
           (Input_File'(Name => U.To_Unbounded_String (""),
                        Content => U.To_Unbounded_String (Stdin)));
      end if;

      return (Ok => True, Files => Result);
   end Load;
end Awk_CLI.Inputs;
