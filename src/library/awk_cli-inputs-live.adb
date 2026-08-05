with Awk_CLI.Inputs.Live.Activation;
with Awk_CLI.Inputs.Live.Reading;
with Awk_CLI.Live_Context_Callbacks;
with System.Address_To_Access_Conversions;

package body Awk_CLI.Inputs.Live is
   use type U.Unbounded_String;
   use type Awk_CLI.Platform.Read_Status;

   package State_Access is new System.Address_To_Access_Conversions (Live_Input_State);

   procedure Initialize
     (State    : out Live_Input_State;
      Context  : in out Invocation_Context;
      Operands : aliased Awk_CLI.Operands.Operand_Vectors.Vector) is
   begin
      --  Callback lifetime invariant: Context and Operands are owned by
      --  Awk_CLI.Invocation.Execute and outlive the synchronous awklib run
      --  that receives State'Address.
      State.Context := Context'Unchecked_Access;
      State.Operands := Operands'Unchecked_Access;
      State.Operand_Index := 0;
      State.Implicit_Stdin_Used := False;
      State.Active := False;
      State.Active_Process := False;
      State.Active_Name := U.Null_Unbounded_String;
      State.Active_Content := U.Null_Unbounded_String;
      State.Active_Position := 1;
      Awk_CLI.Platform.Close_Input (State.Process_Stream);
   end Initialize;

   procedure Close (State : in out Live_Input_State) is
   begin
      Awk_CLI.Platform.Close_Input (State.Process_Stream);
   end Close;

   function Auxiliary_Files
     (Context : Invocation_Context) return Input_File_Vectors.Vector
   is
      Result : Input_File_Vectors.Vector;
   begin
      if Context.Config.Use_Process then
         return Result;
      end if;

      for File of Context.IO.Files loop
         if File.Openable and then File.Readable then
            Result.Append (Input_File'(Name => File.Path, Content => File.Content));
         end if;
      end loop;
      return Result;
   end Auxiliary_Files;

   function Read
     (User_Data    : System.Address;
      Operand_Index : Positive;
      Filename     : out U.Unbounded_String;
      Text         : out U.Unbounded_String;
      End_Of_Input : out Boolean) return Awk_CLI.Platform.Read_Status
   is
      State : constant State_Access.Object_Pointer :=
        State_Access.To_Pointer (User_Data);
      Status : Awk_CLI.Platform.Read_Status;
   begin
      Filename := U.Null_Unbounded_String;
      Text := U.Null_Unbounded_String;
      End_Of_Input := False;

      loop
         if State.Active and then State.Operand_Index /= Operand_Index then
            Awk_CLI.Inputs.Live.Activation.Close_Active_Input (State.all);
         end if;

         if not State.Active then
            if State.Operand_Index = Operand_Index then
               End_Of_Input := True;
               return Awk_CLI.Platform.Read_Success;
            end if;

            Status := Awk_CLI.Inputs.Live.Activation.Activate_Operand
              (State.all, Operand_Index);
            if Status /= Awk_CLI.Platform.Read_Success then
               Filename := State.Active_Name;
               End_Of_Input := True;
               return Status;
            end if;
            if not State.Active then
               End_Of_Input := True;
               return Awk_CLI.Platform.Read_Success;
            end if;
         end if;

         Status := Awk_CLI.Inputs.Live.Reading.Read_Active
           (State.all, Filename, Text, End_Of_Input);
         if Status /= Awk_CLI.Platform.Read_Success or else U.Length (Text) > 0 then
            return Status;
         elsif Filename /= U.Null_Unbounded_String and then not State.Active then
            return Awk_CLI.Platform.Read_Success;
         end if;
      end loop;
   end Read;

   function Write_Output
     (User_Data : System.Address;
      Content   : String) return Boolean
   is
      State : constant State_Access.Object_Pointer :=
        State_Access.To_Pointer (User_Data);
   begin
      return
        Awk_CLI.Live_Context_Callbacks.Write_Output (State.Context.all, Content);
   end Write_Output;

   function Write_Redirection
     (User_Data : System.Address;
      Path      : String;
      Content   : String;
      Append    : Boolean) return Awk_CLI.Redirections.Write_Status
   is
      State : constant State_Access.Object_Pointer :=
        State_Access.To_Pointer (User_Data);
   begin
      return
        Awk_CLI.Live_Context_Callbacks.Write_Redirection
          (State.Context.all, Path, Content, Append);
   end Write_Redirection;

   function Read_Command
     (User_Data : System.Address;
      Command   : String;
      Output    : out U.Unbounded_String) return Boolean
   is
      State : constant State_Access.Object_Pointer :=
        State_Access.To_Pointer (User_Data);
   begin
      return
        Awk_CLI.Live_Context_Callbacks.Read_Command
          (State.Context.all, Command, Output);
   end Read_Command;
end Awk_CLI.Inputs.Live;
