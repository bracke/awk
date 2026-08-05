with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy.Platform_Checks.Prohibited_APIs is
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
         Quiet => False);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src",
            """/bin/sh""",
            Allowed_Files => []) = "",
         "shell executable selection must stay in hostkit");
      Ada_Source.Require_No_Code_Tokens_In_Tree
        ("../src",
         [U.To_Unbounded_String ("GNAT.Expect")],
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-platform.ads",
         "This is not a system-AWK fallback and must not parse AWK source.",
         "platform command runner must document callback-only ownership",
         Quiet => False);
      Files.Require_Contains
        ("../src/library/awk_cli-live_context_callbacks.adb",
         "Only awklib reaches this callback after parsing/evaluating",
         "live command callback must document awklib ownership",
         Quiet => False);
   end Run;
end Awk_Workflow_Source_Policy.Platform_Checks.Prohibited_APIs;
