with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;

package body Awk_Workflow_Source_Policy.Platform_Checks.Platform_Structure is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Run is
   begin
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package Byte_IO is",
         "platform byte-buffer helpers must be grouped",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package Host_Metadata is",
         "platform host metadata helpers must be grouped",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package Command_Execution is",
         "platform command execution helpers must be grouped",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package body File_IO is separate;",
         "platform whole-file I/O helpers must be split into a focused subunit",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package body Input_Streams is separate;",
         "platform input stream helpers must be split into a focused subunit",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package body Command_Execution is separate;",
         "platform command execution helpers must be split into a focused subunit",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package Standard_Streams is",
         "platform standard-stream write helpers must be grouped",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "package body Standard_Streams is separate;",
         "platform standard-stream writes must be split into a focused subunit",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.adb",
         "function Environment_Value_Or_Empty",
         "platform locale lookup must centralize environment value reads",
         Quiet => False);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-platform.adb",
         [U.To_Unbounded_String
            ("when Constraint_Error | Program_Error | Storage_Error =>")],
         Quiet => False);
   end Run;
end Awk_Workflow_Source_Policy.Platform_Checks.Platform_Structure;
