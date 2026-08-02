with Ada.Strings.Unbounded;
with System;
with Awk_CLI.Diagnostics;
with Awk_CLI.Environment;
with Awk_CLI.Inputs;
with Awk_CLI.Operands;
with Awk_CLI.Options;
with Awk_CLI.Platform;
with Awk_CLI.Redirections;

package Awk_CLI.Execution is
   package U renames Ada.Strings.Unbounded;

   type Execution_Result (Ok : Boolean := False) is record
      case Ok is
         when True =>
            Standard_Output : U.Unbounded_String;
            Exit_Status     : Integer := 0;
            Redirections    : Awk_CLI.Redirections.Redirection_Vectors.Vector;
         when False =>
            Diagnostic : Awk_CLI.Diagnostics.Diagnostic;
      end case;
   end record;

   type Live_Output_Writer is access function
     (User_Data : System.Address;
      Content   : String) return Boolean;

   type Live_Redirection_Writer is access function
     (User_Data : System.Address;
      Path      : String;
      Content   : String;
      Append    : Boolean) return Awk_CLI.Redirections.Write_Status;

   type Live_Input_Reader is access function
     (User_Data    : System.Address;
      Operand_Index : Positive;
      Filename     : out U.Unbounded_String;
      Text         : out U.Unbounded_String;
      End_Of_Input : out Boolean) return Awk_CLI.Platform.Read_Status;

   type Live_Command_Reader is access function
     (User_Data : System.Address;
      Command   : String;
      Output    : out U.Unbounded_String) return Boolean;

   function Execute
     (Program_Source  : String;
      Options         : Awk_CLI.Options.Parsed_Options;
      Operands        : Awk_CLI.Operands.Operand_Vectors.Vector;
      Inputs          : Awk_CLI.Inputs.Input_File_Vectors.Vector;
      Environment     : Awk_CLI.Environment.Entry_Vectors.Vector)
      return Execution_Result;

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
      return Execution_Result;

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
      return Execution_Result;

   function Supports_Positional_Runtime_Assignments return Boolean;
   function Supports_Redirection_Append_Mode return Boolean;
   function Supports_Streaming_Execution return Boolean;
   function Interpreter_Version return String;
end Awk_CLI.Execution;
