with Project_Tools.Processes;

with Awk_Tests.Process_Support.Executable_Paths;

package body Awk_Tests.Process_Support.Processes is
   function Environment_Command return String is
     (Project_Tools.Processes.Locate_Command ("env"));

   function Environment_Command_Missing return Captured_Process is
     (Status => -1,
      Output => U.To_Unbounded_String ("env executable is unavailable"));

   function Environment_Awk_Arguments
     (Env  : Argument_Items;
      Awk  : String;
      Args : Process_Arguments) return Process_Arguments
   is
      Result : Process_Arguments;
   begin
      for Item of Env loop
         Result.Append (Item);
      end loop;

      Result.Append (Argument (Awk));

      for Arg of Args loop
         Result.Append (Arg);
      end loop;

      return Result;
   end Environment_Awk_Arguments;

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

   function Run_Awk_With_Environment
     (Label      : String;
      Env        : Argument_Items;
      Args       : Process_Arguments;
      Err_To_Out : Boolean := False;
      Input      : String := "") return Captured_Process
   is
      Command  : constant String := Environment_Command;
      Awk_Path : constant String :=
        (if Err_To_Out
         then Awk_Tests.Process_Support.Executable_Paths.Awk_From_Tests_Directory
         else Awk_Tests.Process_Support.Executable_Paths.Awk_From_Repository_Root);
      Full_Args : constant Process_Arguments :=
        Environment_Awk_Arguments (Env, Awk_Path, Args);
   begin
      if Command = "" then
         return Environment_Command_Missing;
      elsif Err_To_Out then
         return Run_Command_Err_To_Out (Command, Full_Args, Input);
      else
         return Run_Process (Label, "..", Command, Full_Args);
      end if;
   end Run_Awk_With_Environment;

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
