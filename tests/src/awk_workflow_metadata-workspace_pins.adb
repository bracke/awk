with Project_Tools.Alire_Manifests.Validation;

package body Awk_Workflow_Metadata.Workspace_Pins is
   package Manifests renames Project_Tools.Alire_Manifests.Validation;

   procedure Run is
   begin
      Manifests.Require_Workspace_Pin ("../alire.toml", "awklib", "../awklib", Quiet => True);
      Manifests.Require_Workspace_Pin
        ("../alire.toml", "terminal_styles", "../terminal_styles", Quiet => True);
      Manifests.Require_Workspace_Pin ("../alire.toml", "messages", "../messages", Quiet => True);
      Manifests.Require_Workspace_Pin ("../alire.toml", "hostkit", "../hostkit", Quiet => True);
      Manifests.Require_Workspace_Pin ("alire.toml", "awk", "..", Quiet => True);
      Manifests.Require_Workspace_Pin
        ("alire.toml", "project_tools", "../../project_tools", Quiet => True);
      Manifests.Require_Workspace_Pin
        ("alire.toml", "messages", "../../messages", Quiet => True);
   end Run;
end Awk_Workflow_Metadata.Workspace_Pins;
