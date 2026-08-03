with Project_Tools.Processes;

package body Awk_Tests.Process_Harness is
   function Locate_Command (Name : String) return String is
     (Project_Tools.Processes.Locate_Command (Name));

   function Run_Status
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : Argument_List;
      Output  : out Output_Text) return Integer
   is
   begin
      return
        Project_Tools.Processes.Run_Status
          (Label   => Label,
           Dir     => Dir,
           Program => Program,
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   end Run_Status;

   function Command_Output
     (Command    : String;
      Arguments  : Argument_List;
      Input      : String := "";
      Status     : access Integer := null;
      Err_To_Out : Boolean := False) return String
   is
   begin
      return
        Project_Tools.Processes.Command_Output
          (Command    => Command,
           Arguments  => Arguments,
           Input      => Input,
           Status     => Status,
           Err_To_Out => Err_To_Out);
   end Command_Output;
end Awk_Tests.Process_Harness;
