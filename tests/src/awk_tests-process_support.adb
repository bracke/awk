with Ada.Directories;

with Project_Tools.Files;
with Project_Tools.Test_Fixtures;

with Awk_CLI.Localization;

package body Awk_Tests.Process_Support is
   package Fixtures renames Project_Tools.Test_Fixtures;

   function Argument (Value : String) return U.Unbounded_String is
     (Project_Tools.Processes.Argument (Value));

   function No_Arguments return Process_Arguments is
     (Project_Tools.Processes.No_Arguments);

   function Arguments
     (Items : Argument_Items) return Process_Arguments is
     (Project_Tools.Processes.Arguments (Project_Tools.Processes.Argument_Items (Items)));

   function Awk_From_Repository_Root return String is
   begin
      if Project_Tools.Files.File_Exists ("../bin/awk.exe") then
         return "./bin/awk.exe";
      end if;

      return "./bin/awk";
   end Awk_From_Repository_Root;

   function Awk_From_Tests_Directory return String is
   begin
      if Project_Tools.Files.File_Exists ("../bin/awk.exe") then
         return "../bin/awk.exe";
      end if;

      return "../bin/awk";
   end Awk_From_Tests_Directory;

   function Repository_Path (Relative_Path : String) return String is
   begin
      return Ada.Directories.Full_Name ("../" & Relative_Path);
   end Repository_Path;

   function Absolute_Awk_Path return String is
   begin
      return Ada.Directories.Full_Name
        (if Project_Tools.Files.File_Exists ("../bin/awk.exe")
         then "../bin/awk.exe"
         else "../bin/awk");
   end Absolute_Awk_Path;

   function Project_Tools_Preserves_Empty_Arguments return Boolean is
   begin
      --  The project_tools process helper drops an empty string argument on the Windows
      --  runner. The in-memory harness still tests empty direct programs.
      return not Project_Tools.Files.File_Exists ("../bin/awk.exe");
   end Project_Tools_Preserves_Empty_Arguments;

   function Run_Awk_Err_To_Out
     (Args  : Process_Arguments;
      Input : String := "") return Captured_Process
   is
   begin
      return Run_Command_Err_To_Out (Awk_From_Tests_Directory, Args, Input);
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
         Program => Awk_From_Repository_Root,
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
         Program => Absolute_Awk_Path,
         Args    => Args);
   end Run_Awk_In_Directory;

   function Output_String (Result : Captured_Process) return String is
     (U.To_String (Result.Output));

   function Fresh_Process_Temp_Dir (Name : String) return String is
     (Fixtures.Fresh_Temp_Dir ("awk_process_" & Name));

   procedure Cleanup_Process_Temp_Dir (Path : String) is
   begin
      Fixtures.Cleanup (Path);
   end Cleanup_Process_Temp_Dir;

   function Read_Text_File (Path : String) return String is
     (Fixtures.Read_Text_File (Path));

   procedure Write_Text_File (Path : String; Content : String) is
   begin
      Fixtures.Write_Text_File (Path, Content);
   end Write_Text_File;

   function Locale_Text
     (Key       : String;
      Locale    : String := "en";
      Name      : String := "";
      Value     : String := "";
      Detail    : String := "") return String
   is
      Catalog : Awk_CLI.Localization.Catalog;
   begin
      Awk_CLI.Localization.Initialize
        (Catalog, "../resources/messages/catalog.txt", Locale);
      return Awk_CLI.Localization.Text (Catalog, Key, Name, Value, Detail);
   end Locale_Text;

   function English_Text
     (Key       : String;
      Name      : String := "";
      Value     : String := "";
      Detail    : String := "") return String is
     (Locale_Text (Key, "en", Name, Value, Detail));

   function English_Hint (Hint_Key : String) return String is
   begin
      return English_Text
        ("awk.diagnostic.hint",
         Detail => English_Text (Hint_Key));
   end English_Hint;

   function English_Error_Header (Primary : String) return String is
   begin
      return English_Text
        ("awk.diagnostic.header",
         Name   => "severity",
         Value  => English_Text ("awk.diagnostic.label.error"),
         Detail => Primary);
   end English_Error_Header;
end Awk_Tests.Process_Support;
