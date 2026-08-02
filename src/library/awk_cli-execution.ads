with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with System;
with Awk_CLI.Diagnostics;
with Awk_CLI.Environment;
with Awk_CLI.Inputs;
with Awk_CLI.Operands;
with Awk_CLI.Options;

package Awk_CLI.Execution is
   package U renames Ada.Strings.Unbounded;

   type Redirected_Output is record
      Path    : U.Unbounded_String;
      Content : U.Unbounded_String;
      Append  : Boolean := False;
   end record;

   package Redirection_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Redirected_Output);

   type Execution_Result (Ok : Boolean := False) is record
      case Ok is
         when True =>
            Standard_Output : U.Unbounded_String;
            Exit_Status     : Integer := 0;
            Redirections    : Redirection_Vectors.Vector;
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
      Append    : Boolean) return Boolean;

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
      User_Data       : System.Address := System.Null_Address)
      return Execution_Result;

   function Supports_Positional_Runtime_Assignments return Boolean;
   function Supports_Redirection_Append_Mode return Boolean;
   function Supports_Streaming_Execution return Boolean;
   function Interpreter_Version return String;
end Awk_CLI.Execution;
