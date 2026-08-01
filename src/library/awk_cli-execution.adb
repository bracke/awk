with Awklib.Interpreter;
with Awklib;

package body Awk_CLI.Execution is
   package I renames Awklib.Interpreter;
   use type I.Run_Status;

   function Pair (Name, Value : String) return I.Var_Assignment is
     (Name  => U.To_Unbounded_String (Name),
      Value => U.To_Unbounded_String (Value));

   function Execute
     (Program_Source  : String;
      Options         : Awk_CLI.Options.Parsed_Options;
      Operands        : Awk_CLI.Operands.Operand_Vectors.Vector;
      Inputs          : Awk_CLI.Inputs.Input_File_Vectors.Vector;
      Environment     : Awk_CLI.Environment.Entry_Vectors.Vector)
      return Execution_Result
   is
      Assignments  : I.Assignment_Vectors.Vector;
      Env          : I.Assignment_Vectors.Vector;
      Main_Files   : I.Assignment_Vectors.Vector;
      Aux_Files    : I.Assignment_Vectors.Vector;
      Arguments    : I.String_Vectors.Vector;
      Output       : U.Unbounded_String;
      Message      : U.Unbounded_String;
      Written      : I.Assignment_Vectors.Vector;
      Exit_Code    : Integer := 0;
      Status       : I.Run_Status;
   begin
      if Options.Has_Field_Separator then
         Assignments.Append (Pair ("FS", U.To_String (Options.Field_Separator)));
      end if;

      for Item of Options.Initial_Assignments loop
         Assignments.Append (Pair (U.To_String (Item.Name), U.To_String (Item.Value)));
      end loop;

      for Item of Environment loop
         Env.Append (Pair (U.To_String (Item.Name), U.To_String (Item.Value)));
      end loop;

      for Item of Inputs loop
         Main_Files.Append (Pair (U.To_String (Item.Name), U.To_String (Item.Content)));
         if U.To_String (Item.Name) /= "-" and then U.To_String (Item.Name) /= "" then
            Aux_Files.Append (Pair (U.To_String (Item.Name), U.To_String (Item.Content)));
         end if;
      end loop;

      for Item of Operands loop
         Arguments.Append (Item.Text);
      end loop;

      I.Run
        (Program_Source => Program_Source,
         Input          => "",
         Assignments    => Assignments,
         Environment    => Env,
         Filename       => "",
         Output         => Output,
         Exit_Code      => Exit_Code,
         Status         => Status,
         Message        => Message,
         Output_Files   => Written,
         Files          => Aux_Files,
         Input_Files    => Main_Files,
         Arguments      => Arguments);

      if Status = I.Run_Error then
         return
           (Ok => False,
            Diagnostic =>
              Awk_CLI.Diagnostics.Make
                ("awk.interpreter.runtime_failed",
                 Awk_CLI.Diagnostics.Error,
                 Awk_CLI.Diagnostics.Interpreter,
                 Detail => U.To_String (Message)));
      end if;

      declare
         Redirs : Redirection_Vectors.Vector;
      begin
         for Item of Written loop
            Redirs.Append
              (Redirected_Output'(Path => Item.Name, Content => Item.Value, Append => False));
         end loop;
         return
           (Ok => True, Standard_Output => Output, Exit_Status => Exit_Code,
            Redirections => Redirs);
      end;
   exception
      when others =>
         return
           (Ok => False,
            Diagnostic =>
              Awk_CLI.Diagnostics.Make
                ("awk.internal.unexpected_exception",
                 Awk_CLI.Diagnostics.Internal_Error,
                 Awk_CLI.Diagnostics.Internal));
   end Execute;

   function Interpreter_Version return String is (Awklib.Version);
end Awk_CLI.Execution;
