with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy.Platform_Checks is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Run is
   begin
      Ada_Source.Require_No_Code_Tokens_In_Tree
        ("../src",
         [U.To_Unbounded_String ("GNAT.OS_Lib")],
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            """/bin/sh""",
            Allowed_Files => []) = "",
         "shell executable selection must stay in hostkit");
      Files.Require_Contains
        ("../src/library/awk_cli-platform.ads",
         "This is not a system-AWK fallback and must not parse AWK source.",
         "platform command runner must document callback-only ownership",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-live_context_callbacks.adb",
         "Only awklib reaches this callback after parsing/evaluating",
         "live command callback must document awklib ownership",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens_In_Tree
        ("../src",
         [U.To_Unbounded_String ("GNAT.Expect")],
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "while Remaining > 0 loop",
         "standard stream writes must retry partial writes",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package Byte_IO is",
         "platform byte-buffer helpers must be grouped",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package Host_Metadata is",
         "platform host metadata helpers must be grouped",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package Command_Execution is",
         "platform command execution helpers must be grouped",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package body File_IO is separate;",
         "platform whole-file I/O helpers must be split into a focused subunit",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package body Input_Streams is separate;",
         "platform input stream helpers must be split into a focused subunit",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package body Command_Execution is separate;",
         "platform command execution helpers must be split into a focused subunit",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package Standard_Streams is",
         "platform standard-stream write helpers must be grouped",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "function Environment_Value_Or_Empty",
         "platform locale lookup must centralize environment value reads",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform-command_execution.adb",
         "type Command_Run_Files is record",
         "command-getline temp-file state must be grouped",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform-command_execution.adb",
         "procedure Cleanup_Command_Run_Files",
         "command-getline cleanup must be centralized",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-platform-file_io.adb",
         "Natural'Min (Remaining, Natural (Byte_IO.Chunk_Size))",
         "platform file writes must use bounded chunks",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-platform-file_io.adb",
         [U.To_Unbounded_String ("Stream_Element_Array (1 .. Content'Length)")],
         Quiet => True);
   end Run;
end Awk_Workflow_Source_Policy.Platform_Checks;
