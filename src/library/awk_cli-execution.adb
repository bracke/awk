with Awklib.Interpreter;
with Awklib;

with Awk_CLI.Execution.Callbacks;

package body Awk_CLI.Execution is
   package I renames Awklib.Interpreter;
   use type I.Run_Status;
   use type I.Runtime_Operand_Kind;

   function Pair (Name, Value : String) return I.Var_Assignment is
     (Name  => U.To_Unbounded_String (Name),
      Value => U.To_Unbounded_String (Value));

   function Build_Assignments
     (Options : Awk_CLI.Options.Parsed_Options) return I.Assignment_Vectors.Vector
   is
      Result : I.Assignment_Vectors.Vector;
   begin
      if Options.Has_Field_Separator then
         Result.Append (Pair ("FS", U.To_String (Options.Field_Separator)));
      end if;

      for Item of Options.Initial_Assignments loop
         Result.Append (Pair (U.To_String (Item.Name), U.To_String (Item.Value)));
      end loop;

      return Result;
   end Build_Assignments;

   function Build_Environment
     (Environment : Awk_CLI.Environment.Entry_Vectors.Vector)
      return I.Assignment_Vectors.Vector
   is
      Result : I.Assignment_Vectors.Vector;
   begin
      for Item of Environment loop
         Result.Append (Pair (U.To_String (Item.Name), U.To_String (Item.Value)));
      end loop;
      return Result;
   end Build_Environment;

   function Build_Auxiliary_Files
     (Inputs          : Awk_CLI.Inputs.Input_File_Vectors.Vector;
      Auxiliary_Files : Awk_CLI.Inputs.Input_File_Vectors.Vector;
      Live_Input      : Live_Input_Reader) return I.Assignment_Vectors.Vector
   is
      Source : constant Awk_CLI.Inputs.Input_File_Vectors.Vector :=
        (if Live_Input = null then Inputs else Auxiliary_Files);
      Result : I.Assignment_Vectors.Vector;
   begin
      for Item of Source loop
         if U.To_String (Item.Name) /= "-" and then U.To_String (Item.Name) /= "" then
            Result.Append (Pair (U.To_String (Item.Name), U.To_String (Item.Content)));
         end if;
      end loop;
      return Result;
   end Build_Auxiliary_Files;

   function Build_Arguments
     (Operands : Awk_CLI.Operands.Operand_Vectors.Vector) return I.String_Vectors.Vector
   is
      Result : I.String_Vectors.Vector;
   begin
      for Item of Operands loop
         Result.Append (Item.Text);
      end loop;
      return Result;
   end Build_Arguments;

   function Build_Runtime_Operands
     (Operands : Awk_CLI.Operands.Operand_Vectors.Vector) return I.Runtime_Operand_Vectors.Vector
   is
      Result    : I.Runtime_Operand_Vectors.Vector;
      Has_Input : Boolean := False;
   begin
      for Item of Operands loop
         case Item.Kind is
            when Awk_CLI.Operands.Named_File | Awk_CLI.Operands.Standard_Input =>
               Has_Input := True;
               Result.Append
                 (I.Runtime_Operand'
                    (Kind  => I.Input_Operand,
                     Text  => Item.Text,
                     Name  => U.Null_Unbounded_String,
                     Value => U.Null_Unbounded_String));
            when Awk_CLI.Operands.Runtime_Assignment =>
               Result.Append
                 (I.Runtime_Operand'
                    (Kind  => I.Assignment_Operand,
                     Text  => Item.Text,
                     Name  => Item.Name,
                     Value => Item.Value));
         end case;
      end loop;

      if not Has_Input then
         Result.Append
           (I.Runtime_Operand'
              (Kind  => I.Input_Operand,
               Text  => U.Null_Unbounded_String,
               Name  => U.Null_Unbounded_String,
               Value => U.Null_Unbounded_String));
      end if;

      return Result;
   end Build_Runtime_Operands;

   function Build_Run_Result
     (Status    : I.Run_Status;
      Message   : U.Unbounded_String;
      State     : Awk_CLI.Execution.Callbacks.Stream_State;
      Output    : U.Unbounded_String;
      Exit_Code : Integer;
      Redirs    : Awk_CLI.Redirections.Redirection_Vectors.Vector)
      return Execution_Result
   is
   begin
      if Status = I.Run_Error then
         return
           (Ok => False,
            Diagnostic =>
              Awk_CLI.Diagnostics.Make
                ("awk.interpreter.runtime_failed",
                 Awk_CLI.Diagnostics.Error,
                 Awk_CLI.Diagnostics.Interpreter,
                 Detail => U.To_String (Message)));
      elsif Awk_CLI.Execution.Callbacks.Failed (State) then
         return (Ok => False, Diagnostic => Awk_CLI.Execution.Callbacks.Failure (State));
      else
         return
           (Ok => True, Standard_Output => Output, Exit_Status => Exit_Code,
            Redirections => Redirs);
      end if;
   end Build_Run_Result;

   function Execute_Core
     (Program_Source  : String;
      Options         : Awk_CLI.Options.Parsed_Options;
      Operands        : Awk_CLI.Operands.Operand_Vectors.Vector;
      Inputs          : Awk_CLI.Inputs.Input_File_Vectors.Vector;
      Environment     : Awk_CLI.Environment.Entry_Vectors.Vector;
      Live_Input      : Live_Input_Reader;
      Live_Output     : Live_Output_Writer;
      Live_Redirection : Live_Redirection_Writer;
      Live_Command    : Live_Command_Reader;
      Live_User_Data  : System.Address;
      Auxiliary_Files : Awk_CLI.Inputs.Input_File_Vectors.Vector :=
        Awk_CLI.Inputs.Input_File_Vectors.Empty_Vector)
      return Execution_Result
   is
      Assignments  : constant I.Assignment_Vectors.Vector := Build_Assignments (Options);
      Env          : constant I.Assignment_Vectors.Vector := Build_Environment (Environment);
      Aux_Files    : constant I.Assignment_Vectors.Vector :=
        Build_Auxiliary_Files (Inputs, Auxiliary_Files, Live_Input);
      Arguments    : constant I.String_Vectors.Vector := Build_Arguments (Operands);
      Runtime_Operands : I.Runtime_Operand_Vectors.Vector;
      Output       : aliased U.Unbounded_String;
      Message      : U.Unbounded_String;
      Redirs       : aliased Awk_CLI.Redirections.Redirection_Vectors.Vector;
      Exit_Code    : Integer := 0;
      Status       : I.Run_Status;
      State       : aliased Awk_CLI.Execution.Callbacks.Stream_State;
   begin
      Awk_CLI.Execution.Callbacks.Initialize
        (State            => State,
         Inputs           => Inputs'Unchecked_Access,
         Output           => Output'Unchecked_Access,
         Redirs           => Redirs'Unchecked_Access,
         Live_Input       => Live_Input,
         Live_Output      => Live_Output,
         Live_Redirection => Live_Redirection,
         Live_Command     => Live_Command,
         Live_User_Data   => Live_User_Data);

      if Live_Input = null then
         I.Run_Text_Streaming
           (Program_Source => Program_Source,
            Assignments    => Assignments,
            Environment    => Env,
            Initial_Filename => "",
            Read_Text      => Awk_CLI.Execution.Callbacks.Read_Text'Access,
            Write_Output   => Awk_CLI.Execution.Callbacks.Write_Output'Access,
            Write_Redirection => Awk_CLI.Execution.Callbacks.Write_Redirection'Access,
            User_Data      => State'Address,
            Exit_Code      => Exit_Code,
            Status         => Status,
            Message        => Message,
            Files          => Aux_Files,
            Arguments      => Arguments,
            Read_Command   => Awk_CLI.Execution.Callbacks.Read_Command'Access);
      else
         Runtime_Operands := Build_Runtime_Operands (Operands);

         I.Run_Text_Streaming_With_Operands
           (Program_Source => Program_Source,
            Assignments    => Assignments,
            Environment    => Env,
            Initial_Filename => "",
            Operands       => Runtime_Operands,
            Read_Text      => Awk_CLI.Execution.Callbacks.Read_Operand_Text'Access,
            Write_Output   => Awk_CLI.Execution.Callbacks.Write_Output'Access,
            Write_Redirection => Awk_CLI.Execution.Callbacks.Write_Redirection'Access,
            User_Data      => State'Address,
            Exit_Code      => Exit_Code,
            Status         => Status,
            Message        => Message,
            Files          => Aux_Files,
            Read_Command   => Awk_CLI.Execution.Callbacks.Read_Command'Access);
      end if;

      return Build_Run_Result (Status, Message, State, Output, Exit_Code, Redirs);
   exception
      when others =>
         return
           (Ok => False,
            Diagnostic =>
              Awk_CLI.Diagnostics.Make
                ("awk.internal.unexpected_exception",
                 Awk_CLI.Diagnostics.Internal_Error,
                 Awk_CLI.Diagnostics.Internal));
   end Execute_Core;

   function Execute
     (Program_Source  : String;
      Options         : Awk_CLI.Options.Parsed_Options;
      Operands        : Awk_CLI.Operands.Operand_Vectors.Vector;
      Inputs          : Awk_CLI.Inputs.Input_File_Vectors.Vector;
      Environment     : Awk_CLI.Environment.Entry_Vectors.Vector)
      return Execution_Result
   is
   begin
      return Execute_Core
        (Program_Source, Options, Operands, Inputs, Environment,
         Live_Input => null,
         Live_Output => null,
         Live_Redirection => null,
         Live_Command => null,
         Live_User_Data => System.Null_Address);
   end Execute;

   function Execute_Live
     (Program_Source  : String;
      Options         : Awk_CLI.Options.Parsed_Options;
      Operands        : Awk_CLI.Operands.Operand_Vectors.Vector;
      Inputs          : Awk_CLI.Inputs.Input_File_Vectors.Vector;
      Environment     : Awk_CLI.Environment.Entry_Vectors.Vector;
      Write_Output    : not null Live_Output_Writer;
      Write_Redirection : not null Live_Redirection_Writer;
      Read_Command    : Live_Command_Reader := null;
      User_Data       : System.Address := System.Null_Address)
      return Execution_Result
   is
   begin
      return Execute_Core
        (Program_Source, Options, Operands, Inputs, Environment,
         Live_Input => null,
         Live_Output => Write_Output,
         Live_Redirection => Write_Redirection,
         Live_Command => Read_Command,
         Live_User_Data => User_Data);
   end Execute_Live;

   function Execute_Live_Input
     (Program_Source  : String;
      Options         : Awk_CLI.Options.Parsed_Options;
      Operands        : Awk_CLI.Operands.Operand_Vectors.Vector;
      Environment     : Awk_CLI.Environment.Entry_Vectors.Vector;
      Read_Input      : not null Live_Input_Reader;
      Write_Output    : not null Live_Output_Writer;
      Write_Redirection : not null Live_Redirection_Writer;
      Read_Command    : Live_Command_Reader := null;
      User_Data       : System.Address := System.Null_Address;
      Auxiliary_Files : Awk_CLI.Inputs.Input_File_Vectors.Vector :=
        Awk_CLI.Inputs.Input_File_Vectors.Empty_Vector)
      return Execution_Result
   is
   begin
      return Execute_Core
        (Program_Source, Options, Operands,
         Awk_CLI.Inputs.Input_File_Vectors.Empty_Vector, Environment,
         Live_Input => Read_Input,
         Live_Output => Write_Output,
         Live_Redirection => Write_Redirection,
         Live_Command => Read_Command,
         Live_User_Data => User_Data,
         Auxiliary_Files => Auxiliary_Files);
   end Execute_Live_Input;

   function Interpreter_Version return String is (Awklib.Version);

   function Supports_Positional_Runtime_Assignments return Boolean is (True);
   function Supports_Redirection_Append_Mode return Boolean is (True);
   function Supports_Streaming_Execution return Boolean is (True);
end Awk_CLI.Execution;
