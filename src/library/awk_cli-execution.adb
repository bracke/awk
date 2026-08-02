with Awklib.Interpreter;
with Awklib;
with System.Address_To_Access_Conversions;

package body Awk_CLI.Execution is
   package I renames Awklib.Interpreter;
   use type I.Run_Status;
   use type I.Runtime_Operand_Kind;

   function Pair (Name, Value : String) return I.Var_Assignment is
     (Name  => U.To_Unbounded_String (Name),
      Value => U.To_Unbounded_String (Value));

   type Input_Vector_Access is access constant Awk_CLI.Inputs.Input_File_Vectors.Vector;
   type Output_Access is access all U.Unbounded_String;
   type Redirection_Vector_Access is access all Awk_CLI.Redirections.Redirection_Vectors.Vector;

   type Stream_State is record
      Inputs      : Input_Vector_Access;
      Live_Input  : Live_Input_Reader := null;
      Output      : Output_Access;
      Redirs      : Redirection_Vector_Access;
      Live_Output : Live_Output_Writer := null;
      Live_Redirection : Live_Redirection_Writer := null;
      Live_User_Data : System.Address := System.Null_Address;
      Failed     : Boolean := False;
      Failure    : Awk_CLI.Diagnostics.Diagnostic;
      Input_Index : Natural := 0;
   end record;

   package Stream_State_Access is new System.Address_To_Access_Conversions (Stream_State);

   procedure Read_Text
     (User_Data    : System.Address;
      Filename     : out U.Unbounded_String;
      Text         : out U.Unbounded_String;
      End_Of_Input : out Boolean)
   is
      State : constant Stream_State_Access.Object_Pointer :=
        Stream_State_Access.To_Pointer (User_Data);
   begin
      if State.Failed then
         Filename := U.Null_Unbounded_String;
         Text := U.Null_Unbounded_String;
         End_Of_Input := True;
         return;
      end if;

      if State.Input_Index >= Natural (State.Inputs.Length) then
         Filename := U.Null_Unbounded_String;
         Text := U.Null_Unbounded_String;
         End_Of_Input := True;
      else
         State.Input_Index := State.Input_Index + 1;
         Filename := State.Inputs.Element (State.Input_Index).Name;
         Text := State.Inputs.Element (State.Input_Index).Content;
         End_Of_Input := False;
      end if;
   end Read_Text;

   procedure Read_Operand_Text
     (User_Data     : System.Address;
      Operand_Index : Positive;
      Filename      : out U.Unbounded_String;
      Text          : out U.Unbounded_String;
      End_Of_Input  : out Boolean)
   is
      State : constant Stream_State_Access.Object_Pointer :=
        Stream_State_Access.To_Pointer (User_Data);
      Status : Awk_CLI.Platform.Read_Status;
   begin
      if State.Failed then
         Filename := U.Null_Unbounded_String;
         Text := U.Null_Unbounded_String;
         End_Of_Input := True;
         return;
      end if;

      Status :=
        State.Live_Input.all
          (State.Live_User_Data, Operand_Index, Filename, Text, End_Of_Input);
      case Status is
         when Awk_CLI.Platform.Read_Success =>
            null;
         when Awk_CLI.Platform.Open_Failed =>
            State.Failed := True;
            if U.To_String (Filename) = "-" or else U.To_String (Filename) = "" then
               State.Failure :=
                 Awk_CLI.Diagnostics.Make
                   ("awk.standard_input.read_failed",
                    Awk_CLI.Diagnostics.Error,
                    Awk_CLI.Diagnostics.Input);
            else
               State.Failure :=
                 Awk_CLI.Diagnostics.Make
                   ("awk.input_file.open_failed",
                    Awk_CLI.Diagnostics.Error,
                    Awk_CLI.Diagnostics.Input,
                    Name => "path",
                    Value => U.To_String (Filename));
            end if;
            Filename := U.Null_Unbounded_String;
            Text := U.Null_Unbounded_String;
            End_Of_Input := True;
         when Awk_CLI.Platform.Read_Failed =>
            State.Failed := True;
            if U.To_String (Filename) = "-" or else U.To_String (Filename) = "" then
               State.Failure :=
                 Awk_CLI.Diagnostics.Make
                   ("awk.standard_input.read_failed",
                    Awk_CLI.Diagnostics.Error,
                    Awk_CLI.Diagnostics.Input);
            else
               State.Failure :=
                 Awk_CLI.Diagnostics.Make
                   ("awk.input_file.read_failed",
                    Awk_CLI.Diagnostics.Error,
                    Awk_CLI.Diagnostics.Input,
                    Name => "path",
                    Value => U.To_String (Filename));
            end if;
            Filename := U.Null_Unbounded_String;
            Text := U.Null_Unbounded_String;
            End_Of_Input := True;
      end case;
   end Read_Operand_Text;

   procedure Write_Output (User_Data : System.Address; Text : String) is
      State : constant Stream_State_Access.Object_Pointer :=
        Stream_State_Access.To_Pointer (User_Data);
   begin
      if State.Failed then
         return;
      end if;

      if State.Live_Output = null then
         U.Append (State.Output.all, Text);
      elsif not State.Live_Output.all (State.Live_User_Data, Text) then
         State.Failed := True;
         State.Failure :=
           Awk_CLI.Diagnostics.Make
             ("awk.standard_output.write_failed",
              Awk_CLI.Diagnostics.Error,
              Awk_CLI.Diagnostics.Output);
      end if;
   end Write_Output;

   procedure Write_Redirection
     (User_Data : System.Address;
      Name      : String;
      Text      : String;
      Append    : Boolean;
      Truncate  : Boolean)
   is
      pragma Unreferenced (Truncate);
      State : constant Stream_State_Access.Object_Pointer :=
        Stream_State_Access.To_Pointer (User_Data);
      Result : Awk_CLI.Redirections.Write_Status;
   begin
      if State.Failed then
         return;
      end if;

      if State.Live_Redirection = null then
         State.Redirs.Append
           (Awk_CLI.Redirections.Redirected_Output'
              (Path    => U.To_Unbounded_String (Name),
               Content => U.To_Unbounded_String (Text),
              Append  => Append));
      else
         Result := State.Live_Redirection.all (State.Live_User_Data, Name, Text, Append);
         case Result is
            when Awk_CLI.Redirections.Write_Success =>
               null;
            when Awk_CLI.Redirections.Open_Failed =>
               State.Failed := True;
               State.Failure :=
                 Awk_CLI.Diagnostics.Make
                   ("awk.output_file.open_failed",
                    Awk_CLI.Diagnostics.Error,
                    Awk_CLI.Diagnostics.Output,
                    Name => "path",
                    Value => Name);
            when Awk_CLI.Redirections.Write_Failed =>
               State.Failed := True;
               State.Failure :=
                 Awk_CLI.Diagnostics.Make
                   ("awk.output_file.write_failed",
                    Awk_CLI.Diagnostics.Error,
                    Awk_CLI.Diagnostics.Output,
                    Name => "path",
                    Value => Name);
         end case;
      end if;
   end Write_Redirection;

   function Execute_Core
     (Program_Source  : String;
      Options         : Awk_CLI.Options.Parsed_Options;
      Operands        : Awk_CLI.Operands.Operand_Vectors.Vector;
      Inputs          : Awk_CLI.Inputs.Input_File_Vectors.Vector;
      Environment     : Awk_CLI.Environment.Entry_Vectors.Vector;
      Live_Input      : Live_Input_Reader;
      Live_Output     : Live_Output_Writer;
      Live_Redirection : Live_Redirection_Writer;
      Live_User_Data  : System.Address;
      Auxiliary_Files : Awk_CLI.Inputs.Input_File_Vectors.Vector :=
        Awk_CLI.Inputs.Input_File_Vectors.Empty_Vector)
      return Execution_Result
   is
      Assignments  : I.Assignment_Vectors.Vector;
      Env          : I.Assignment_Vectors.Vector;
      Aux_Files    : I.Assignment_Vectors.Vector;
      Arguments    : I.String_Vectors.Vector;
      Runtime_Operands : I.Runtime_Operand_Vectors.Vector;
      Output       : aliased U.Unbounded_String;
      Message      : U.Unbounded_String;
      Redirs       : aliased Awk_CLI.Redirections.Redirection_Vectors.Vector;
      Exit_Code    : Integer := 0;
      Status       : I.Run_Status;
      State       : aliased Stream_State :=
        (Inputs      => Inputs'Unchecked_Access,
         Live_Input  => Live_Input,
         Output      => Output'Unchecked_Access,
         Redirs      => Redirs'Unchecked_Access,
         Live_Output => Live_Output,
         Live_Redirection => Live_Redirection,
         Live_User_Data => Live_User_Data,
         Failed      => False,
         Failure     =>
           Awk_CLI.Diagnostics.Make
             ("awk.internal.unexpected_exception",
              Awk_CLI.Diagnostics.Internal_Error,
              Awk_CLI.Diagnostics.Internal),
         Input_Index => 0);
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

      if Live_Input = null then
         for Item of Inputs loop
            if U.To_String (Item.Name) /= "-" and then U.To_String (Item.Name) /= "" then
               Aux_Files.Append (Pair (U.To_String (Item.Name), U.To_String (Item.Content)));
            end if;
         end loop;
      else
         for Item of Auxiliary_Files loop
            if U.To_String (Item.Name) /= "-" and then U.To_String (Item.Name) /= "" then
               Aux_Files.Append (Pair (U.To_String (Item.Name), U.To_String (Item.Content)));
            end if;
         end loop;
      end if;

      for Item of Operands loop
         Arguments.Append (Item.Text);
         if Live_Input /= null then
            case Item.Kind is
               when Awk_CLI.Operands.Named_File | Awk_CLI.Operands.Standard_Input =>
                  Runtime_Operands.Append
                    (I.Runtime_Operand'
                       (Kind => I.Input_Operand,
                        Text => Item.Text,
                        Name => U.Null_Unbounded_String,
                        Value => U.Null_Unbounded_String));
               when Awk_CLI.Operands.Runtime_Assignment =>
                  Runtime_Operands.Append
                    (I.Runtime_Operand'
                       (Kind => I.Assignment_Operand,
                        Text => Item.Text,
                        Name => Item.Name,
                        Value => Item.Value));
            end case;
         end if;
      end loop;

      if Live_Input = null then
         I.Run_Text_Streaming
           (Program_Source => Program_Source,
            Assignments    => Assignments,
            Environment    => Env,
            Initial_Filename => "",
            Read_Text      => Read_Text'Access,
            Write_Output   => Write_Output'Access,
            Write_Redirection => Write_Redirection'Access,
            User_Data      => State'Address,
            Exit_Code      => Exit_Code,
            Status         => Status,
            Message        => Message,
            Files          => Aux_Files,
            Arguments      => Arguments);
      else
         declare
            Has_Input : Boolean := False;
         begin
            for Item of Runtime_Operands loop
               if Item.Kind = I.Input_Operand then
                  Has_Input := True;
               end if;
            end loop;
            if not Has_Input then
               Runtime_Operands.Append
                 (I.Runtime_Operand'
                    (Kind => I.Input_Operand,
                     Text => U.Null_Unbounded_String,
                     Name => U.Null_Unbounded_String,
                     Value => U.Null_Unbounded_String));
            end if;
         end;

         I.Run_Text_Streaming_With_Operands
           (Program_Source => Program_Source,
            Assignments    => Assignments,
            Environment    => Env,
            Initial_Filename => "",
            Operands       => Runtime_Operands,
            Read_Text      => Read_Operand_Text'Access,
            Write_Output   => Write_Output'Access,
            Write_Redirection => Write_Redirection'Access,
            User_Data      => State'Address,
            Exit_Code      => Exit_Code,
            Status         => Status,
            Message        => Message,
            Files          => Aux_Files);
      end if;

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

      if State.Failed then
         return (Ok => False, Diagnostic => State.Failure);
      end if;

      return
        (Ok => True, Standard_Output => Output, Exit_Status => Exit_Code,
         Redirections => Redirs);
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
      User_Data       : System.Address := System.Null_Address)
      return Execution_Result
   is
   begin
      return Execute_Core
        (Program_Source, Options, Operands, Inputs, Environment,
         Live_Input => null,
         Live_Output => Write_Output,
         Live_Redirection => Write_Redirection,
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
         Live_User_Data => User_Data,
         Auxiliary_Files => Auxiliary_Files);
   end Execute_Live_Input;

   function Interpreter_Version return String is (Awklib.Version);

   function Supports_Positional_Runtime_Assignments return Boolean is (True);
   function Supports_Redirection_Append_Mode return Boolean is (True);
   function Supports_Streaming_Execution return Boolean is (True);
end Awk_CLI.Execution;
