with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Awk_Workflow_Build_Output;
with Awk_Workflow_Catalogs;
with Awk_Workflow_Conformance;
with Awk_Workflow_Docs;
with Awk_Workflow_Drift;
with Awk_Workflow_Install;
with Awk_Workflow_Metadata;
with Awk_Workflow_Packaging;
with Awk_Workflow_Source_Policy;
with Project_Tools.Alire;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

procedure Awk_Workflows is
   package CLI renames Ada.Command_Line;
   package Files renames Project_Tools.Files;

   Root : constant String := "..";
   No_Arguments : constant GNAT.OS_Lib.Argument_List (1 .. 0) := [];

   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Build is
   begin
      Project_Tools.Alire.Run_Build (Directory => Root);
      Project_Tools.Alire.Run_Build (Directory => ".");
   end Build;

   procedure Release_Build is
   begin
      Project_Tools.Alire.Run_Build (Directory => Root, Release_Mode => True);
      Project_Tools.Alire.Run_Build (Directory => ".", Release_Mode => True);
   end Release_Build;

   procedure Run_AUnit is
   begin
      Project_Tools.Release_Checks.Run
        ("./bin/awk_tests_main", ".", "./bin/awk_tests_main", No_Arguments);
   end Run_AUnit;

   procedure Test is
   begin
      Project_Tools.Alire.Run_Build (Directory => ".");
      Run_AUnit;
   end Test;

   procedure Require_Clean_Repository is
   begin
      Project_Tools.Release_Checks.Require_Clean_Git_Worktree
        ("awk", Root, Quiet => True);
   end Require_Clean_Repository;

   procedure Core_Quality_Gates is
   begin
      Awk_Workflow_Metadata.Run;
      Awk_Workflow_Docs.Run;
      Awk_Workflow_Catalogs.Run;
      Awk_Workflow_Conformance.Run;
      Awk_Workflow_Drift.Exit_Statuses;
      Awk_Workflow_Drift.Options;
      Awk_Workflow_Source_Policy.Package_Manifest_Policy;
      Awk_Workflow_Source_Policy.Run;
   end Core_Quality_Gates;

   procedure Verify is
   begin
      Build;
      Test;
      Core_Quality_Gates;
      Awk_Workflow_Install.Boundary;
      Awk_Workflow_Build_Output.Run;
   end Verify;

   procedure Clean is
   begin
      Files.Delete_Tree ("../obj");
      Files.Delete_Tree ("../bin");
      Files.Delete_Tree ("../dist");
      Files.Delete_Tree ("obj");
      Files.Delete_Tree ("bin");
      Put_Info ("cleaned build outputs");
   end Clean;

   procedure Usage is
   begin
      Ada.Text_IO.Put_Line
        ("usage: awk_workflows build|test|verify|docs|clean|package|release");
   end Usage;

   Command : constant String :=
     (if CLI.Argument_Count = 0 then "verify" else CLI.Argument (1));
begin
   if Command = "build" then
      Build;
      Awk_Workflow_Build_Output.Run;
   elsif Command = "test" then
      Test;
      Awk_Workflow_Build_Output.Run;
   elsif Command = "verify" then
      Verify;
   elsif Command = "docs" then
      Awk_Workflow_Docs.Run;
   elsif Command = "clean" then
      Clean;
   elsif Command = "package" then
      Awk_Workflow_Packaging.Run;
      Awk_Workflow_Build_Output.Run;
   elsif Command = "release" then
      Require_Clean_Repository;
      Release_Build;
      Run_AUnit;
      Core_Quality_Gates;
      Awk_Workflow_Install.Boundary;
      Awk_Workflow_Packaging.Run (Release_Mode => True);
      Awk_Workflow_Build_Output.Run;
   elsif Command = "--help" or else Command = "-h" then
      Usage;
   else
      Usage;
      CLI.Set_Exit_Status (CLI.Failure);
   end if;
exception
   when Program_Error =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "workflow gate failed");
      CLI.Set_Exit_Status (CLI.Failure);
   when Error : others =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "unexpected workflow failure: " & Ada.Exceptions.Exception_Information (Error));
      CLI.Set_Exit_Status (CLI.Failure);
end Awk_Workflows;
