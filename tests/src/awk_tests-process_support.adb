with Project_Tools.Files;
with Project_Tools.Test_Fixtures;

with Awk_CLI.Localization;

package body Awk_Tests.Process_Support is
   package Fixtures renames Project_Tools.Test_Fixtures;

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

   function Process_Harness_Preserves_Empty_Arguments return Boolean is
   begin
      --  The process harness drops an empty string argument on the Windows
      --  runner. The in-memory harness still tests empty direct programs.
      return not Project_Tools.Files.File_Exists ("../bin/awk.exe");
   end Process_Harness_Preserves_Empty_Arguments;

   function Run_Awk_Err_To_Out
     (Args  : Awk_Tests.Process_Harness.Argument_List;
      Input : String := "") return Captured_Process
   is
   begin
      return Run_Command_Err_To_Out (Awk_From_Tests_Directory, Args, Input);
   end Run_Awk_Err_To_Out;

   function Run_Command_Err_To_Out
     (Command : String;
      Args    : Awk_Tests.Process_Harness.Argument_List;
      Input   : String := "") return Captured_Process
   is
      Status : aliased Integer := -1;
      Output : constant String :=
        Awk_Tests.Process_Harness.Command_Output
          (Command    => Command,
           Arguments  => Args,
           Input      => Input,
           Status     => Status'Access,
           Err_To_Out => True);
   begin
      return
        (Status => Status,
         Output => U.To_Unbounded_String (Output));
   end Run_Command_Err_To_Out;

   function Run_Process
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : Awk_Tests.Process_Harness.Argument_List) return Captured_Process
   is
      Output : Awk_Tests.Process_Harness.Output_Text;
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => Label,
           Dir     => Dir,
           Program => Program,
           Args    => Args,
           Output  => Output);
   begin
      return (Status => Status, Output => Output);
   end Run_Process;

   function Run_Awk
     (Label : String;
      Args  : Awk_Tests.Process_Harness.Argument_List) return Captured_Process
   is
   begin
      return Run_Process
        (Label   => Label,
         Dir     => "..",
         Program => Awk_From_Repository_Root,
         Args    => Args);
   end Run_Awk;

   function Output_String (Result : Captured_Process) return String is
     (U.To_String (Result.Output));

   procedure Ensure_Filesystem_Fixture_Directory is
   begin
      Fixtures.Make_Directory ("../tests/fixtures/filesystem");
   end Ensure_Filesystem_Fixture_Directory;

   function Read_Text_File (Path : String) return String is
     (Fixtures.Read_Text_File (Path));

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
