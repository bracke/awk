with Ada.Text_IO;

with Awk_Workflow_Metadata.Project_Files;
with Awk_Workflow_Metadata.Root_Crate;
with Awk_Workflow_Metadata.Tests_Crate;
with Awk_Workflow_Metadata.Workspace_Pins;
with Project_Tools.Test_Fixtures;
with Project_Tools.TOML;

package body Awk_Workflow_Metadata is
   package Fixtures renames Project_Tools.Test_Fixtures;
   package TOML renames Project_Tools.TOML;

   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Run is
      Root_Alire  : constant String := Fixtures.Read_Text_File ("../alire.toml");
      Tests_Alire : constant String := Fixtures.Read_Text_File ("alire.toml");
      Root_Version : constant String :=
        TOML.String_Value_After (Root_Alire, "version =", Root_Alire'First);
      Awklib_Constraint : constant String :=
        TOML.String_Value_After (Root_Alire, "awklib =", Root_Alire'First);

      function Constraint_Version (Constraint : String) return String is
      begin
         if Constraint'Length > 0
           and then (Constraint (Constraint'First) = '~'
                     or else Constraint (Constraint'First) = '=')
         then
            return Constraint (Constraint'First + 1 .. Constraint'Last);
         else
            return Constraint;
         end if;
      end Constraint_Version;

      Awklib_Version : constant String := Constraint_Version (Awklib_Constraint);
   begin
      Awk_Workflow_Metadata.Root_Crate.Run
        (Root_Alire, Root_Version, Awklib_Version);
      Awk_Workflow_Metadata.Tests_Crate.Run (Tests_Alire, Root_Version);
      Awk_Workflow_Metadata.Workspace_Pins.Run;
      Awk_Workflow_Metadata.Project_Files.Run;
      Put_Info ("metadata checks passed");
   end Run;
end Awk_Workflow_Metadata;
