with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Test_Fixtures;

with GNAT.OS_Lib;

with Awk_CLI.Localization;

package body Awk_Tests.Process_Support is
   package Fixtures renames Project_Tools.Test_Fixtures;

   function Argument (Value : String) return U.Unbounded_String is
     (U.To_Unbounded_String (Value));

   function No_Arguments return Process_Arguments is
      Result : Process_Arguments;
   begin
      return Result;
   end No_Arguments;

   function Arguments
     (Items : Argument_Items) return Process_Arguments
   is
      Result : Process_Arguments;
   begin
      for Item of Items loop
         Result.Append (Item);
      end loop;
      return Result;
   end Arguments;

   function To_OS_Arguments
     (Args : Process_Arguments) return GNAT.OS_Lib.Argument_List
   is
      Result : GNAT.OS_Lib.Argument_List (1 .. Natural (Args.Length));
   begin
      for Index in 1 .. Natural (Args.Length) loop
         Result (Index) := new String'(U.To_String (Args.Element (Index)));
      end loop;
      return Result;
   end To_OS_Arguments;

   procedure Free_OS_Arguments (Args : in out GNAT.OS_Lib.Argument_List) is
   begin
      for Item of Args loop
         GNAT.OS_Lib.Free (Item);
      end loop;
   end Free_OS_Arguments;

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

   function Project_Tools_Preserves_Empty_Arguments return Boolean is
   begin
      --  The project_tools process helper drops an empty string argument on the Windows
      --  runner. The in-memory harness still tests empty direct programs.
      return not Project_Tools.Files.File_Exists ("../bin/awk.exe");
   end Project_Tools_Preserves_Empty_Arguments;

   function Run_Command_Err_To_Out
     (Command : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Input   : String := "") return Captured_Process;

   function Run_Awk_Err_To_Out
     (Args  : GNAT.OS_Lib.Argument_List;
      Input : String := "") return Captured_Process
   is
   begin
      return Run_Command_Err_To_Out (Awk_From_Tests_Directory, Args, Input);
   end Run_Awk_Err_To_Out;

   function Run_Awk_Err_To_Out
     (Args  : Process_Arguments;
      Input : String := "") return Captured_Process
   is
      OS_Args : GNAT.OS_Lib.Argument_List := To_OS_Arguments (Args);
      Result  : Captured_Process;
   begin
      Result := Run_Awk_Err_To_Out (OS_Args, Input);
      Free_OS_Arguments (OS_Args);
      return Result;
   exception
      when others =>
         Free_OS_Arguments (OS_Args);
         raise;
   end Run_Awk_Err_To_Out;

   function Run_Command_Err_To_Out
     (Command : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Input   : String := "") return Captured_Process
   is
      Status : aliased Integer := -1;
      Output : constant String :=
        Project_Tools.Processes.Command_Output
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

   function Run_Command_Err_To_Out
     (Command : String;
      Args    : Process_Arguments;
      Input   : String := "") return Captured_Process
   is
      OS_Args : GNAT.OS_Lib.Argument_List := To_OS_Arguments (Args);
      Result  : Captured_Process;
   begin
      Result := Run_Command_Err_To_Out (Command, OS_Args, Input);
      Free_OS_Arguments (OS_Args);
      return Result;
   exception
      when others =>
         Free_OS_Arguments (OS_Args);
         raise;
   end Run_Command_Err_To_Out;

   function Run_Process
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List) return Captured_Process
   is
      Output : Project_Tools.Processes.Unbounded_String;
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => Label,
           Dir     => Dir,
           Program => Program,
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      return (Status => Status, Output => Output);
   end Run_Process;

   function Run_Process
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : Process_Arguments) return Captured_Process
   is
      OS_Args : GNAT.OS_Lib.Argument_List := To_OS_Arguments (Args);
      Result  : Captured_Process;
   begin
      Result := Run_Process (Label, Dir, Program, OS_Args);
      Free_OS_Arguments (OS_Args);
      return Result;
   exception
      when others =>
         Free_OS_Arguments (OS_Args);
         raise;
   end Run_Process;

   function Run_Awk
     (Label : String;
      Args  : GNAT.OS_Lib.Argument_List) return Captured_Process
   is
   begin
      return Run_Process
        (Label   => Label,
         Dir     => "..",
         Program => Awk_From_Repository_Root,
         Args    => Args);
   end Run_Awk;

   function Run_Awk
     (Label : String;
      Args  : Process_Arguments) return Captured_Process
   is
      OS_Args : GNAT.OS_Lib.Argument_List := To_OS_Arguments (Args);
      Result  : Captured_Process;
   begin
      Result := Run_Awk (Label, OS_Args);
      Free_OS_Arguments (OS_Args);
      return Result;
   exception
      when others =>
         Free_OS_Arguments (OS_Args);
         raise;
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
