with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;

package body Awk_Workflow_Source_Policy.Platform_Checks.Command_File_Contracts is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Run is
   begin
      Files.Require_Contains
        ("../src/library/awk_cli-platform-command_execution.adb",
         "type Command_Run_Files is record",
         "command-getline temp-file state must be grouped",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform-command_execution.adb",
         "procedure Cleanup_Command_Run_Files",
         "command-getline cleanup must be centralized",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform-file_io.adb",
         "Natural'Min (Remaining, Natural (Byte_IO.Chunk_Size))",
         "platform file writes must use bounded chunks",
         Quiet => False);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-platform-file_io.adb",
         [U.To_Unbounded_String ("Stream_Element_Array (1 .. Content'Length)")],
         Quiet => False);
   end Run;
end Awk_Workflow_Source_Policy.Platform_Checks.Command_File_Contracts;
