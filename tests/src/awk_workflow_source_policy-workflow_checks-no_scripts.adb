with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy.Workflow_Checks.No_Scripts is
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
      Workflow_Script : constant String :=
        Files.First_File_Name_Containing
          ("..",
           Name_Tokens =>
             [U.To_Unbounded_String (".sh"),
              U.To_Unbounded_String (".py"),
              U.To_Unbounded_String (".ps1"),
              U.To_Unbounded_String ("Makefile"),
              U.To_Unbounded_String (".js")],
           Skip_Entries =>
             [U.To_Unbounded_String (".git"),
              U.To_Unbounded_String ("alire"),
              U.To_Unbounded_String ("obj"),
              U.To_Unbounded_String ("bin"),
              U.To_Unbounded_String ("dist"),
              U.To_Unbounded_String ("config")]);
   begin
      Ada_Source.Require_No_Code_Tokens_In_Tree
        ("../src",
         ([U.To_Unbounded_String ("gawk"),
           U.To_Unbounded_String ("mawk"),
           U.To_Unbounded_String ("nawk")]),
         Quiet => False);
      Require
        (Workflow_Script = "",
         "workflow logic must not use shell or scripting files: " & Workflow_Script);
   end Run;

end Awk_Workflow_Source_Policy.Workflow_Checks.No_Scripts;
