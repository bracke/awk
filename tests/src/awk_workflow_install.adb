with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Text;

package body Awk_Workflow_Install is
   package Files renames Project_Tools.Files;
   package Proc renames Project_Tools.Processes;
   package Text renames Project_Tools.Text;
   package U renames Ada.Strings.Unbounded;

   Root : constant String := "..";

   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Boundary is
      Prefix : constant String := Files.Join (Files.Temp_Dir, "awk-install-boundary");
      Run_Dir : constant String := Files.Join (Files.Temp_Dir, "awk-install-run-cwd");
      Output : Proc.Unbounded_String;
      Install_Args : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("-n"),
         new String'("install"),
         new String'("--prefix=" & Prefix)];
      Version_Args : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--version")];
   begin
      Proc.Require_Command ("alr", "alr executable not found", Quiet => True);
      Files.Delete_Tree (Prefix);
      Files.Delete_Tree (Run_Dir);
      Ada.Directories.Create_Path (Run_Dir);

      declare
         Alr : constant String := Proc.Locate_Command ("alr");
      begin
         Proc.Run ("alr install", Root, Alr, Install_Args, Quiet => True);
      end;

      Files.Require_File (Prefix & "/bin/awk", "installed awk executable missing");
      Proc.Run
        ("installed awk --version", Run_Dir, Prefix & "/bin/awk", Version_Args,
         Output, Quiet => True);
      Require (Text.Contains (U.To_String (Output), "awk 0.1.0"),
               "installed awk version output is unexpected");

      Files.Delete_Tree (Prefix);
      Files.Delete_Tree (Run_Dir);
      Put_Info ("install boundary checks passed");
   end Boundary;
end Awk_Workflow_Install;
