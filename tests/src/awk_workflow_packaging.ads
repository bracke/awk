package Awk_Workflow_Packaging is
   --  Release package assembly gate for the awk workflow tool.

   --  @return Number of files included in the release package.
   function File_Count return Natural;
   --  Return the number of files included in the release package.
   --  @return Number of files included in the release package.

   --  @param Index Package file index.
   --  @return Relative package file path for Index.
   function File_Path (Index : Positive) return String with Pre => Index <= File_Count;
   --  Return the relative package file path for Index.
   --  @param Index Package file index.
   --  @return Relative package file path for Index.

   --  @param Release_Mode Whether to build with release profile first.
   procedure Run (Release_Mode : Boolean := False);
   --  Build and assemble the distributable package, validating required files
   --  and package manifest entries.
   --  @param Release_Mode Whether to build with release profile first.
end Awk_Workflow_Packaging;
