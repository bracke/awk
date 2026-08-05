package Awk_Workflow_Packaging.Manifest_Files is
   function File_Count return Natural;
   --  Return the number of files included in the release package.

   function File_Path (Index : Positive) return String with Pre => Index <= File_Count;
   --  Return the relative package file path for Index.
end Awk_Workflow_Packaging.Manifest_Files;
