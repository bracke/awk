with Project_Tools.Processes;

with Awk_Tests.Process_Support.Executable_Paths;

package body Awk_Tests.Process_Support.Processes is
   function Run_Awk_Err_To_Out
     (Args  : Process_Arguments;
      Input : String := "") return Captured_Process
   is
   begin
      return Run_Command_Err_To_Out
        (Awk_Tests.Process_Support.Executable_Paths.Awk_From_Tests_Directory,
         Args,
         Input);
   end Run_Awk_Err_To_Out;

   function Run_Command_Err_To_Out
     (Command : String;
      Args    : Process_Arguments;
      Input   : String := "") return Captured_Process
   is
      Result : constant Project_Tools.Processes.Captured_Process :=
        Project_Tools.Processes.Capture_Command
          (Command    => Command,
           Arguments  => Args,
           Input      => Input,
           Err_To_Out => True);
   begin
      return
        (Status => Result.Status,
         Output => Result.Output);
   end Run_Command_Err_To_Out;

   function Run_Process
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : Process_Arguments) return Captured_Process
   is
      Result : constant Project_Tools.Processes.Captured_Process :=
        Project_Tools.Processes.Capture
          (Label   => Label,
           Dir     => Dir,
           Program => Program,
           Args    => Args,
           Quiet   => True);
   begin
      return
        (Status => Result.Status,
         Output => Result.Output);
   end Run_Process;

   function Run_Awk
     (Label : String;
      Args  : Process_Arguments) return Captured_Process
   is
   begin
      return Run_Process
        (Label   => Label,
         Dir     => "..",
         Program => Awk_Tests.Process_Support.Executable_Paths.Awk_From_Repository_Root,
         Args    => Args);
   end Run_Awk;

   function Run_Awk_In_Directory
     (Label : String;
      Dir   : String;
      Args  : Process_Arguments) return Captured_Process
   is
   begin
      return Run_Process
        (Label   => Label,
         Dir     => Dir,
         Program => Awk_Tests.Process_Support.Executable_Paths.Absolute_Awk_Path,
         Args    => Args);
   end Run_Awk_In_Directory;
end Awk_Tests.Process_Support.Processes;
