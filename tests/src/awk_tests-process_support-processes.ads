package Awk_Tests.Process_Support.Processes is
   function Run_Awk_Err_To_Out
     (Args  : Process_Arguments;
      Input : String := "") return Captured_Process;

   function Run_Command_Err_To_Out
     (Command : String;
      Args    : Process_Arguments;
      Input   : String := "") return Captured_Process;

   function Run_Process
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : Process_Arguments) return Captured_Process;

   function Run_Awk
     (Label : String;
      Args  : Process_Arguments) return Captured_Process;

   function Run_Awk_In_Directory
     (Label : String;
      Dir   : String;
      Args  : Process_Arguments) return Captured_Process;
end Awk_Tests.Process_Support.Processes;
