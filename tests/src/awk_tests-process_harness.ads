with Ada.Strings.Unbounded;
with GNAT.OS_Lib;

package Awk_Tests.Process_Harness is
   subtype Argument_List is GNAT.OS_Lib.Argument_List;
   subtype Output_Text is Ada.Strings.Unbounded.Unbounded_String;

   --  @param Name Executable name to find on PATH.
   --  @return Absolute executable path, or an empty string when not found.
   function Locate_Command (Name : String) return String;

   --  @param Label Human-readable command label.
   --  @param Dir Working directory for the child process.
   --  @param Program Executable to run.
   --  @param Args Argument list passed to Program.
   --  @param Output Receives captured standard output.
   --  @return Child process exit status.
   function Run_Status
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : Argument_List;
      Output  : out Output_Text) return Integer;

   --  @param Command Executable to run.
   --  @param Arguments Argument list passed to Command.
   --  @param Input Standard input for the child process.
   --  @param Status Child status receiver.
   --  @param Err_To_Out Whether standard error is merged into output.
   --  @return Captured command output.
   function Command_Output
     (Command    : String;
      Arguments  : Argument_List;
      Input      : String := "";
      Status     : access Integer := null;
      Err_To_Out : Boolean := False) return String;
end Awk_Tests.Process_Harness;
