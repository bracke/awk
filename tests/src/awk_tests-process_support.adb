with Ada.Directories;

with Awk_Tests.Process_Support.Argument_Builders;
with Awk_Tests.Process_Support.Executable_Paths;
with Awk_Tests.Process_Support.Fixture_Files;
with Awk_Tests.Process_Support.Localization_Text;
with Awk_Tests.Process_Support.Processes;

package body Awk_Tests.Process_Support is
   function Argument (Value : String) return U.Unbounded_String is
     (Awk_Tests.Process_Support.Argument_Builders.Argument (Value));

   function No_Arguments return Process_Arguments is
     (Awk_Tests.Process_Support.Argument_Builders.No_Arguments);

   function Arguments
     (Items : Argument_Items) return Process_Arguments is
     (Awk_Tests.Process_Support.Argument_Builders.Arguments (Items));

   function Awk_From_Repository_Root return String is
     (Awk_Tests.Process_Support.Executable_Paths.Awk_From_Repository_Root);

   function Awk_From_Tests_Directory return String is
     (Awk_Tests.Process_Support.Executable_Paths.Awk_From_Tests_Directory);

   function Repository_Path (Relative_Path : String) return String is
   begin
      return Ada.Directories.Full_Name ("../" & Relative_Path);
   end Repository_Path;

   function Project_Tools_Preserves_Empty_Arguments return Boolean is
     (Awk_Tests.Process_Support.Executable_Paths.Preserves_Empty_Arguments);

   function Run_Awk_Err_To_Out
     (Args  : Process_Arguments;
      Input : String := "") return Captured_Process
   is (Awk_Tests.Process_Support.Processes.Run_Awk_Err_To_Out (Args, Input));

   function Run_Awk_With_Environment
     (Label      : String;
      Env        : Argument_Items;
      Args       : Process_Arguments;
      Err_To_Out : Boolean := False;
      Input      : String := "") return Captured_Process
   is (Awk_Tests.Process_Support.Processes.Run_Awk_With_Environment
         (Label, Env, Args, Err_To_Out, Input));

   function Run_Command_Err_To_Out
     (Command : String;
      Args    : Process_Arguments;
      Input   : String := "") return Captured_Process
   is (Awk_Tests.Process_Support.Processes.Run_Command_Err_To_Out
         (Command, Args, Input));

   function Run_Process
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : Process_Arguments) return Captured_Process
   is (Awk_Tests.Process_Support.Processes.Run_Process
         (Label, Dir, Program, Args));

   function Run_Awk
     (Label : String;
      Args  : Process_Arguments) return Captured_Process
   is (Awk_Tests.Process_Support.Processes.Run_Awk (Label, Args));

   function Run_Awk_In_Directory
     (Label : String;
      Dir   : String;
      Args  : Process_Arguments) return Captured_Process
   is (Awk_Tests.Process_Support.Processes.Run_Awk_In_Directory
         (Label, Dir, Args));

   function Output_String (Result : Captured_Process) return String is
     (U.To_String (Result.Output));

   function Fresh_Process_Temp_Dir (Name : String) return String is
     (Awk_Tests.Process_Support.Fixture_Files.Fresh_Process_Temp_Dir (Name));

   procedure Cleanup_Process_Temp_Dir (Path : String) is
   begin
      Awk_Tests.Process_Support.Fixture_Files.Cleanup_Process_Temp_Dir (Path);
   end Cleanup_Process_Temp_Dir;

   function Read_Text_File (Path : String) return String is
     (Awk_Tests.Process_Support.Fixture_Files.Read_Text_File (Path));

   procedure Write_Text_File (Path : String; Content : String) is
   begin
      Awk_Tests.Process_Support.Fixture_Files.Write_Text_File (Path, Content);
   end Write_Text_File;

   function Locale_Text
     (Key       : String;
      Locale    : String := "en";
      Name      : String := "";
      Value     : String := "";
      Detail    : String := "") return String
   is (Awk_Tests.Process_Support.Localization_Text.Locale_Text
         (Key, Locale, Name, Value, Detail));

   function English_Text
     (Key       : String;
      Name      : String := "";
      Value     : String := "";
      Detail    : String := "") return String is
     (Awk_Tests.Process_Support.Localization_Text.English_Text
        (Key, Name, Value, Detail));

   function English_Hint (Hint_Key : String) return String is
     (Awk_Tests.Process_Support.Localization_Text.English_Hint (Hint_Key));

   function English_Error_Header (Primary : String) return String is
     (Awk_Tests.Process_Support.Localization_Text.English_Error_Header (Primary));
end Awk_Tests.Process_Support;
