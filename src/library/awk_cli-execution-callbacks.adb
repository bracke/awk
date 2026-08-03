with System.Address_To_Access_Conversions;

package body Awk_CLI.Execution.Callbacks is
   use type Awk_CLI.Platform.Read_Status;

   --  awklib's streaming callbacks carry one opaque address. The objects
   --  referenced here are aliased locals in Execute_Core and remain alive until
   --  the synchronous awklib run returns. Do not store these addresses outside
   --  the dynamic extent of that call.
   package Stream_State_Access is new System.Address_To_Access_Conversions (Stream_State);

   function Is_Standard_Input_Name (Filename : U.Unbounded_String) return Boolean is
      Value : constant String := U.To_String (Filename);
   begin
      return Value = "-" or else Value = "";
   end Is_Standard_Input_Name;

   function Make_Input_Failure
     (Status   : Awk_CLI.Platform.Read_Status;
      Filename : U.Unbounded_String) return Awk_CLI.Diagnostics.Diagnostic
   is
   begin
      if Is_Standard_Input_Name (Filename) then
         return
           Awk_CLI.Diagnostics.Make
             ("awk.standard_input.read_failed",
              Awk_CLI.Diagnostics.Error,
              Awk_CLI.Diagnostics.Input);
      elsif Status = Awk_CLI.Platform.Open_Failed then
         return
           Awk_CLI.Diagnostics.Make
             ("awk.input_file.open_failed",
              Awk_CLI.Diagnostics.Error,
              Awk_CLI.Diagnostics.Input,
              Name => "path",
              Value => U.To_String (Filename));
      else
         return
           Awk_CLI.Diagnostics.Make
             ("awk.input_file.read_failed",
              Awk_CLI.Diagnostics.Error,
              Awk_CLI.Diagnostics.Input,
              Name => "path",
              Value => U.To_String (Filename));
      end if;
   end Make_Input_Failure;

   procedure Set_Failure
     (State      : in out Stream_State;
      Diagnostic : Awk_CLI.Diagnostics.Diagnostic) is
   begin
      State.Has_Failure := True;
      State.Failure_Value := Diagnostic;
   end Set_Failure;

   procedure Initialize
     (State            : out Stream_State;
      Inputs           : not null access constant Awk_CLI.Inputs.Input_File_Vectors.Vector;
      Output           : not null access U.Unbounded_String;
      Redirs           : not null access Awk_CLI.Redirections.Redirection_Vectors.Vector;
      Live_Input       : Live_Input_Reader;
      Live_Output      : Live_Output_Writer;
      Live_Redirection : Live_Redirection_Writer;
      Live_Command     : Live_Command_Reader;
      Live_User_Data   : System.Address) is
   begin
      State.Inputs := Input_Vector_Access (Inputs);
      State.Live_Input := Live_Input;
      State.Output := Output_Access (Output);
      State.Redirs := Redirection_Vector_Access (Redirs);
      State.Live_Output := Live_Output;
      State.Live_Redirection := Live_Redirection;
      State.Live_Command := Live_Command;
      State.Live_User_Data := Live_User_Data;
      State.Has_Failure := False;
      State.Failure_Value :=
        Awk_CLI.Diagnostics.Make
          ("awk.internal.unexpected_exception",
           Awk_CLI.Diagnostics.Internal_Error,
           Awk_CLI.Diagnostics.Internal);
      State.Input_Index := 0;
   end Initialize;

   procedure Read_Text
     (User_Data    : System.Address;
      Filename     : out U.Unbounded_String;
      Text         : out U.Unbounded_String;
      End_Of_Input : out Boolean)
   is
      State : constant Stream_State_Access.Object_Pointer :=
        Stream_State_Access.To_Pointer (User_Data);
   begin
      if State.Has_Failure then
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
      if State.Has_Failure then
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
         when Awk_CLI.Platform.Open_Failed | Awk_CLI.Platform.Read_Failed =>
            Set_Failure (State.all, Make_Input_Failure (Status, Filename));
            Filename := U.Null_Unbounded_String;
            Text := U.Null_Unbounded_String;
            End_Of_Input := True;
      end case;
   end Read_Operand_Text;

   procedure Write_Output (User_Data : System.Address; Text : String) is
      State : constant Stream_State_Access.Object_Pointer :=
        Stream_State_Access.To_Pointer (User_Data);
   begin
      if State.Has_Failure then
         return;
      end if;

      if State.Live_Output = null then
         U.Append (State.Output.all, Text);
      elsif not State.Live_Output.all (State.Live_User_Data, Text) then
         Set_Failure
           (State.all,
            Awk_CLI.Diagnostics.Make
              ("awk.standard_output.write_failed",
               Awk_CLI.Diagnostics.Error,
               Awk_CLI.Diagnostics.Output));
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
      if State.Has_Failure then
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
               Set_Failure
                 (State.all,
                  Awk_CLI.Diagnostics.Make
                    ("awk.output_file.open_failed",
                     Awk_CLI.Diagnostics.Error,
                     Awk_CLI.Diagnostics.Output,
                     Name => "path",
                     Value => Name));
            when Awk_CLI.Redirections.Write_Failed =>
               Set_Failure
                 (State.all,
                  Awk_CLI.Diagnostics.Make
                    ("awk.output_file.write_failed",
                     Awk_CLI.Diagnostics.Error,
                     Awk_CLI.Diagnostics.Output,
                     Name => "path",
                     Value => Name));
         end case;
      end if;
   end Write_Redirection;

   procedure Read_Command
     (User_Data : System.Address;
      Command   : String;
      Text      : out U.Unbounded_String;
      Available : out Boolean)
   is
      State : constant Stream_State_Access.Object_Pointer :=
        Stream_State_Access.To_Pointer (User_Data);
   begin
      if State.Has_Failure then
         Text := U.Null_Unbounded_String;
         Available := False;
      elsif State.Live_Command /= null then
         Available := State.Live_Command.all (State.Live_User_Data, Command, Text);
      else
         Text := U.Null_Unbounded_String;
         Available := False;
      end if;
   end Read_Command;

   function Failed (State : Stream_State) return Boolean is (State.Has_Failure);

   function Failure (State : Stream_State) return Awk_CLI.Diagnostics.Diagnostic is
     (State.Failure_Value);
end Awk_CLI.Execution.Callbacks;
